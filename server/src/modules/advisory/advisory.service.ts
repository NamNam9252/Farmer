import { ResolvedAdvisoryInput } from "../../schema/advisory.schema.js";

type RiskLevel = 'Low' | 'Medium' | 'High';

interface Recommendation {
  stage: string;
  action: string;
  reason: string;
  riskLevel: RiskLevel;
}

const RISK_ORDER: Record<RiskLevel, number> = { High: 0, Medium: 1, Low: 2 };

const getStage = (days: number): string => {
  if (days <= 10) return 'germination';
  if (days <= 30) return 'vegetative';
  if (days <= 50) return 'flowering';
  return 'fruiting';
};

export class AdvisoryService {
  getRecommendation(input: ResolvedAdvisoryInput): Recommendation[] {
    const stage = getStage(input.days_since_sowing);
    const recommendations: Recommendation[] = [];

    const add = (action: string, reason: string, riskLevel: RiskLevel) =>
      recommendations.push({ stage, action, reason, riskLevel });

    // --- PEST ---
    if (input.pest_reported) {
      add(
        'Apply pesticide immediately',
        'Active pest activity reported in the field',
        'High'
      );
      add(
        'Inspect neighboring plots for pest spread',
        'Pests often spread to adjacent fields; early detection limits damage',
        'Medium'
      );
    }

    // --- WATER / MOISTURE ---
    if (input.soil_moisture === 'low' && input.rain_probability < 40) {
      add(
        'Irrigate within 24 hours',
        'Soil moisture is critically low and no significant rainfall is expected',
        'High'
      );
    }

    if (input.soil_moisture === 'low' && input.rain_probability >= 40 && input.rain_probability < 70) {
      add(
        'Monitor soil moisture closely and prepare irrigation as backup',
        'Soil moisture is low but moderate rainfall is possible',
        'Medium'
      );
    }

    if (input.soil_moisture === 'high' && input.rain_probability > 60) {
      add(
        'Ensure drainage channels are clear to prevent waterlogging',
        'Soil is already saturated and more rain is expected',
        'High'
      );
    }

    if (input.soil_moisture === 'high' && stage === 'flowering') {
      add(
        'Avoid any additional irrigation',
        'Excess moisture during flowering can cause root rot and flower drop',
        'Medium'
      );
    }

    // --- TEMPERATURE ---
    if (input.temperature > 38) {
      add(
        'Apply light irrigation to cool the soil and reduce heat stress',
        'Temperatures above 38°C cause heat stress and can damage crops',
        'High'
      );
    }

    if (input.temperature > 35 && stage === 'flowering') {
      add(
        'Consider shade nets if available',
        'High temperatures during flowering reduce pollination success',
        'Medium'
      );
    }

    if (input.temperature < 10) {
      add(
        'Cover crops or use mulching to protect from cold stress',
        'Temperatures below 10°C can cause frost damage and slow growth',
        'High'
      );
    }

    if (input.temperature < 15 && stage === 'germination') {
      add(
        'Delay sowing or use cold-resistant seed varieties',
        'Cold temperatures significantly slow germination rates',
        'Medium'
      );
    }

    // --- HUMIDITY ---
    if (input.humidity > 80 && stage === 'flowering' && input.temperature >= 20 && input.temperature <= 30) {
      add(
        'Apply preventive fungicide spray',
        'High humidity during flowering in moderate temperatures creates high fungal disease risk',
        'Medium'
      );
    }

    if (input.humidity > 85 && stage === 'fruiting') {
      add(
        'Apply antifungal treatment and improve field ventilation',
        'Very high humidity during fruiting stage significantly increases mold and rot risk',
        'High'
      );
    }

    if (input.humidity < 30) {
      add(
        'Increase irrigation frequency to compensate for high evaporation',
        'Very low humidity causes rapid soil and plant moisture loss',
        'Medium'
      );
    }

    // --- NITROGEN ---
    if (input.soil_n === 'low' && stage === 'vegetative') {
      if (input.rain_probability > 60) {
        add(
          'Delay nitrogen fertilizer application until after expected rainfall',
          'Applying fertilizer before heavy rain risks nutrient washout',
          'Medium'
        );
      } else {
        add(
          'Apply 40kg urea per acre',
          'Nitrogen deficiency during vegetative stage stunts leaf and stem growth',
          'Medium'
        );
      }
    }

    if (input.soil_n === 'low' && stage === 'fruiting') {
      add(
        'Apply foliar nitrogen spray for faster absorption',
        'Nitrogen deficiency during fruiting reduces yield and fruit quality',
        'High'
      );
    }

    // --- PHOSPHORUS ---
    if (input.soil_p === 'low' && stage === 'germination') {
      add(
        'Apply phosphorus-rich fertilizer (DAP) near root zone',
        'Phosphorus is critical for root development during germination',
        'High'
      );
    }

    if (input.soil_p === 'low' && stage === 'flowering') {
      add(
        'Apply superphosphate fertilizer to support flower development',
        'Phosphorus deficiency during flowering reduces bloom and fruit set',
        'Medium'
      );
    }

    // --- POTASSIUM ---
    if (input.soil_k === 'low' && stage === 'fruiting') {
      add(
        'Apply potassium fertilizer (MOP or SOP) immediately',
        'Potassium is essential for fruit sizing and quality during fruiting stage',
        'High'
      );
    }

    if (input.soil_k === 'low' && input.pest_reported) {
      add(
        'Prioritize potassium supplementation alongside pest treatment',
        'Low potassium weakens plant immunity and makes pest damage worse',
        'Medium'
      );
    }

    // --- COMBINED NUTRIENT DEFICIENCY ---
    const deficientNutrients = [
      input.soil_n === 'low' ? 'Nitrogen' : null,
      input.soil_p === 'low' ? 'Phosphorus' : null,
      input.soil_k === 'low' ? 'Potassium' : null,
    ].filter(Boolean);

    if (deficientNutrients.length >= 2) {
      add(
        'Apply a balanced NPK fertilizer to address multiple deficiencies',
        `${deficientNutrients.join(' and ')} are all deficient — a combined NPK application is more efficient`,
        'Medium'
      );
    }

    // --- STAGE SPECIFIC ---
    if (stage === 'germination' && input.soil_moisture === 'medium') {
      add(
        'Maintain consistent soil moisture to support uniform germination',
        'Germination requires steady moisture — avoid letting soil dry out',
        'Low'
      );
    }

    if (stage === 'fruiting' && input.soil_moisture === 'low') {
      add(
        'Increase irrigation to support fruit development',
        'Inadequate water during fruiting causes fruit drop and poor sizing',
        'High'
      );
    }

    // --- DEFAULT ---
    if (recommendations.length === 0) {
      add(
        'No immediate action required',
        'Field conditions are within acceptable ranges for current growth stage',
        'Low'
      );
    }

    return recommendations.sort(
      (a, b) => RISK_ORDER[a.riskLevel] - RISK_ORDER[b.riskLevel]
    );
  }
}