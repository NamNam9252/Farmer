import { Request, Response, NextFunction } from 'express';
import { AdvisoryService } from './advisory.service.js';
import { WeatherService } from '../weather/weather.service.js';
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
  const startTime = Date.now();
  try {
    console.log('[AdvisoryController] Incoming recommendation request');

    const parsed = advisorySchema.safeParse(req.body);
    console.log(parsed);
    if (!parsed.success) {
      console.warn('[AdvisoryController] Request validation failed');
      res.status(400).json({
        success: false,
        message: 'Invalid input',
        error: parsed.error.flatten(),
      });
      return;
    }

    const input = parsed.data;
    console.log(
      `[AdvisoryController] Input accepted | crop=${input.crop} | days=${input.days_since_sowing} | lat=${input.latitude} | lon=${input.longitude}`
    );

    // Always prefer live weather from the wrapper service so advisory stays current.
    let liveWeather: Awaited<ReturnType<WeatherService['getWeather']>> | null = null;
    try {
      console.log('[AdvisoryController] Fetching live weather from WeatherService');
      liveWeather = await getWeatherService().getWeather(
        input.latitude,
        input.longitude
      );
      console.log(
        `[AdvisoryController] Live weather resolved | temp=${liveWeather.temperature}C | humidity=${liveWeather.humidity}% | rainProb=${liveWeather.rain_probability}%`
      );
    } catch {
      console.warn('[AdvisoryController] Live weather fetch failed, falling back to request payload weather');
      liveWeather = null;
    }

    const temperature = liveWeather?.temperature ?? input.temperature;
    const humidity = liveWeather?.humidity ?? input.humidity;
    const rain_probability = liveWeather?.rain_probability ?? input.rain_probability;

    if (
      temperature === undefined ||
      humidity === undefined ||
      rain_probability === undefined
    ) {
      console.error('[AdvisoryController] Weather context unresolved; returning 502');
      res.status(502).json({
        success: false,
        message: 'Unable to resolve required weather context for advisory',
      });
      return;
    }

    const resolved: ResolvedAdvisoryInput = {
      ...input,
      temperature,
      humidity,
      rain_probability,
    };

    const result = await getAdvisoryService().getRecommendation(resolved);
    const durationMs = Date.now() - startTime;
    console.log(
      `[AdvisoryController] Recommendation success | count=${result.length} | weatherSource=${liveWeather ? 'live_openweather' : 'request_payload'} | durationMs=${durationMs}`
    );

    res.status(200).json({
      success: true,
      message: 'Recommendation generated',
      weatherSource: liveWeather ? 'live_openweather' : 'request_payload',
      weatherUsed: {
        temperature,
        humidity,
        rain_probability,
      },
      data: result,
    });
  } catch (error) {
    const durationMs = Date.now() - startTime;
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.error(`[AdvisoryController] Recommendation failed | durationMs=${durationMs} | error=${message}`);
    next(error);
  }
};