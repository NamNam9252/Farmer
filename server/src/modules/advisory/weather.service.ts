interface WeatherData {
  temperature: number;
  humidity: number;
  rain_probability: number;
}

export class WeatherService {
  async getWeather(latitude: number, longitude: number): Promise<WeatherData> {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,relative_humidity_2m&hourly=precipitation_probability&timezone=auto&forecast_days=1`;

    const res = await fetch(url);
    if (!res.ok) throw new Error(`Weather API failed with status ${res.status}`);

    const data = await res.json() as any;

    const temperature = data.current.temperature_2m;
    const humidity = data.current.relative_humidity_2m;

    // Average precipitation probability over next 6 hours
    const next6h: number[] = data.hourly.precipitation_probability.slice(0, 6);
    const rain_probability = Math.round(
      next6h.reduce((a: number, b: number) => a + b, 0) / next6h.length
    );

    return { temperature, humidity, rain_probability };
  }
}