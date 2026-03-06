import { Request, Response, NextFunction } from 'express';
import { AdvisoryService } from './advisory.service.js';
import { WeatherService } from './weather.service.js';
import { advisorySchema, ResolvedAdvisoryInput } from '../../schema/advisory.schema.js';

let advisoryService: AdvisoryService | null = null;
let weatherService: WeatherService | null = null;

const getAdvisoryService = () => {
  if (!advisoryService) advisoryService = new AdvisoryService();
  return advisoryService;
};

const getWeatherService = () => {
  if (!weatherService) weatherService = new WeatherService();
  return weatherService;
};

export const getRecommendation = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const parsed = advisorySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        success: false,
        message: 'Invalid input',
        error: parsed.error.flatten(),
      });
      return;
    }

    const input = parsed.data;

    // Fetch weather from Open-Meteo if any weather field is missing
    let temperature = input.temperature;
    let humidity = input.humidity;
    let rain_probability = input.rain_probability;

    if (
      temperature === undefined ||
      humidity === undefined ||
      rain_probability === undefined
    ) {
      const weather = await getWeatherService().getWeather(
        input.latitude,
        input.longitude
      );
      temperature = temperature ?? weather.temperature;
      humidity = humidity ?? weather.humidity;
      rain_probability = rain_probability ?? weather.rain_probability;
    }

    const resolved: ResolvedAdvisoryInput = {
      ...input,
      temperature,
      humidity,
      rain_probability,
    };

    const result = getAdvisoryService().getRecommendation(resolved);

    res.status(200).json({
      success: true,
      message: 'Recommendation generated',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};