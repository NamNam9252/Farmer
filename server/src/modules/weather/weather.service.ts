interface DailyForecast {
  date: string;
  maxTemp: number;
  minTemp: number;
  humidity: number;
  rainSum: number;
  rainProbability: number;
  summary: string;
}

interface HourlyForecast {
  time: string;
  temp: number;
  humidity: number;
  rainProbability: number;
}

interface WeatherAlert {
  sender: string;
  event: string;
  start: number;
  end: number;
  description: string;
}

interface WeatherData {
  temperature: number;
  humidity: number;
  rain_probability: number;
  overview: string;
  forecast: DailyForecast[];
  hourly: HourlyForecast[];
  alerts: WeatherAlert[];
}

export class WeatherService {
  private apiKey = process.env.OPENWEATHER_API_KEY;

  async getWeather(latitude: number, longitude: number): Promise<WeatherData> {
    if (!this.apiKey) {
      throw new Error('OPENWEATHER_API_KEY is not set in environment variables');
    }

    const units = 'metric';
    const currentWeatherUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&units=${units}&appid=${this.apiKey}`;
    const forecastUrl = `https://api.openweathermap.org/data/2.5/forecast?lat=${latitude}&lon=${longitude}&units=${units}&appid=${this.apiKey}`;

    const [currentRes, forecastRes] = await Promise.all([
      fetch(currentWeatherUrl),
      fetch(forecastUrl)
    ]);

    if (!currentRes.ok) throw new Error(`OpenWeather Current Weather API failed with status ${currentRes.status}`);
    if (!forecastRes.ok) throw new Error(`OpenWeather Forecast API failed with status ${forecastRes.status}`);

    const currentData = await currentRes.json() as any;
    const forecastData = await forecastRes.json() as any;

    // --- Current conditions ---
    const temperature = currentData.main.temp;
    const humidity = currentData.main.humidity;
    
    // 2.5 Forecast provides 'pop' (probability of precipitation) in the list items
    const rain_probability = forecastData.list?.[0]?.pop ? Math.round(forecastData.list[0].pop * 100) : 0;

    // --- Synthesize Daily Forecast (pick midday entries) ---
    // The 2.5 forecast provides 5 days of data with 3-hour steps
    const dailyMap = new Map<string, any>();
    
    forecastData.list.forEach((item: any) => {
      const date = new Date(item.dt * 1000).toISOString().split('T')[0];
      const hour = new Date(item.dt * 1000).getUTCHours();

      if (!dailyMap.has(date)) {
        dailyMap.set(date, {
          date: date,
          maxTemp: item.main.temp_max,
          minTemp: item.main.temp_min,
          humidity: item.main.humidity,
          rainSum: (item.rain?.['3h'] || 0),
          rainProbability: Math.round((item.pop || 0) * 100),
          summary: item.weather[0]?.description || '',
          score: Math.abs(hour - 12) // We want to pick the entry closest to midday for the main daily summary
        });
      } else {
        const existing = dailyMap.get(date);
        // Update min/max for the day
        existing.maxTemp = Math.max(existing.maxTemp, item.main.temp_max);
        existing.minTemp = Math.min(existing.minTemp, item.main.temp_min);
        // Accumulate rain
        existing.rainSum += (item.rain?.['3h'] || 0);
        // Update rain probability (pick the highest for the day)
        existing.rainProbability = Math.max(existing.rainProbability, Math.round((item.pop || 0) * 100));
        
        // If this entry is closer to midday, update the summary and humidity
        const currentScore = Math.abs(hour - 12);
        if (currentScore < existing.score) {
          existing.summary = item.weather[0]?.description || '';
          existing.humidity = item.main.humidity;
          existing.score = currentScore;
        }
      }
    });

    const forecast: DailyForecast[] = Array.from(dailyMap.values()).map(d => ({
      date: d.date,
      maxTemp: Math.round(d.maxTemp),
      minTemp: Math.round(d.minTemp),
      humidity: d.humidity,
      rainSum: Number(d.rainSum.toFixed(2)),
      rainProbability: d.rainProbability,
      summary: d.summary,
    })).slice(0, 5); // 2.5 Free only gives ~5 days

    // --- Synthesize Hourly Forecast ---
    // Note: 2.5 only gives 3-hour steps. We'll return them as they are.
    const hourly: HourlyForecast[] = forecastData.list.map((h: any) => ({
      time: new Date(h.dt * 1000).toISOString(),
      temp: h.main.temp,
      humidity: h.main.humidity,
      rainProbability: Math.round((h.pop || 0) * 100),
    })).slice(0, 24); // Show first 24 slots (spanning 72 hours)

    // --- Alerts & AI Overview (Not available in 2.5 Free) ---
    const alerts: WeatherAlert[] = [];
    const overview = "";

    return {
      temperature,
      humidity,
      rain_probability,
      overview,
      forecast,
      hourly,
      alerts,
    };
  }
}
