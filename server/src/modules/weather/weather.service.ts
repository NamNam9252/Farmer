  interface DailyForecast {
  date: string;         // e.g. "2026-03-08"
  maxTemp: number;
  minTemp: number;
  humidity: number;     // % (current for today, avg for others)
  rainSum: number;      // mm
  rainProbability: number; // % (next 6h for today, daily max for others)
}

interface WeatherData {
  temperature: number;
  humidity: number;
  rain_probability: number;
  forecast: DailyForecast[];
}

export class WeatherService {
  async getWeather(latitude: number, longitude: number): Promise<WeatherData> {
    const url =
      `https://api.open-meteo.com/v1/forecast` +
      `?latitude=${latitude}&longitude=${longitude}` +
      `&current=temperature_2m,relative_humidity_2m` +
      `&hourly=precipitation_probability,relative_humidity_2m` +
      `&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max` +
      `&timezone=auto` +
      `&forecast_days=5`;

    const res = await fetch(url);
    if (!res.ok) throw new Error(`Weather API failed with status ${res.status}`);

    const data = await res.json() as any;

    // --- Current conditions ---
    const temperature: number = data.current.temperature_2m;
    const humidityCurrent: number = Math.round(data.current.relative_humidity_2m);

    // Average precipitation probability over next 6 hours (today)
    const next6hProb: number[] = data.hourly.precipitation_probability.slice(0, 6);
    const rain_probability = Math.round(
      next6hProb.reduce((a: number, b: number) => a + b, 0) / next6hProb.length
    );

    // --- Daily 5-day forecast ---
    const days: string[] = data.daily.time;
    const maxTemps: number[] = data.daily.temperature_2m_max;
    const minTemps: number[] = data.daily.temperature_2m_min;
    const rainSums: number[] = data.daily.precipitation_sum;
    const rainProbs: number[] = data.daily.precipitation_probability_max;
    
    // Aggregate hourly humidity into daily averages
    const hourlyHumidity: number[] = data.hourly.relative_humidity_2m;
    const dailyHumidity: number[] = [];
    for (let i = 0; i < 5; i++) {
        const dayHumidity = hourlyHumidity.slice(i * 24, (i + 1) * 24);
        const avg = dayHumidity.reduce((a, b) => a + b, 0) / dayHumidity.length;
        dailyHumidity.push(Math.round(avg));
    }

    const forecast: DailyForecast[] = days.map((date, i) => {
      // Consistency: for index 0 (Today), use the same values as the Home Page
      const isToday = i === 0;
      
      return {
        date,
        maxTemp: Math.round(maxTemps[i]),
        minTemp: Math.round(minTemps[i]),
        // For today, show current humidity. For future, show daily average.
        humidity: isToday ? humidityCurrent : dailyHumidity[i],
        rainSum: Math.round(rainSums[i] * 10) / 10,
        // For today, show next 6 hours avg. For future, show daily max.
        rainProbability: isToday ? rain_probability : Math.round(rainProbs[i]),
      };
    });

    return { 
      temperature, 
      humidity: humidityCurrent, 
      rain_probability, 
      forecast 
    };
  }
}
