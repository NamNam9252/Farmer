import { Request, Response, NextFunction } from 'express';
import { WeatherService } from './weather.service.js';

let weatherService: WeatherService | null = null;

const getWeatherService = () => {
  if (!weatherService) weatherService = new WeatherService();
  return weatherService;
};

export const getWeather = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const lat = parseFloat(req.query.lat as string);
    const lon = parseFloat(req.query.lon as string);

    if (isNaN(lat) || isNaN(lon)) {
      res.status(400).json({
        success: false,
        message: 'lat and lon query parameters are required and must be numbers',
      });
      return;
    }

    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      res.status(400).json({
        success: false,
        message: 'lat must be between -90 and 90, lon between -180 and 180',
      });
      return;
    }

    const data = await getWeatherService().getWeather(lat, lon);

    res.status(200).json({
      success: true,
      message: 'Weather data fetched successfully',
      data,
    });
  } catch (error) {
    next(error);
  }
};
