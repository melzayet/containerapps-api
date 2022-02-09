using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using IDemoActorInterface;
using Dapr.Actors;
using Dapr.Actors.Client;
using Dapr.Client;


namespace DemoActorApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> _logger;

        public WeatherForecastController(ILogger<WeatherForecastController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public async Task<string> Get()
        {
          // Create an actor Id.
            var actorId = new ActorId("abc");

            // Make strongly typed Actor calls with Remoting.
            // DemoActor is the type registered with Dapr runtime in the service.
            var proxy = ActorProxy.Create<IDemoActor>(actorId, "DemoActor");

            try{
                MyData currentData = await proxy.GetData();                
                if(currentData != null){
                    return "Points: " + currentData.Points + ", Highest Temp: " + currentData.HighestTemp;
                }
            }
              catch(Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
            return "no data";
        }

        [HttpPost]
        public async Task<string> SetWeatherData(WeatherForecast weatherForecast)
        {                                     
            int points =0, highestTemp= 0;

            // Create an actor Id.
            var actorId = new ActorId("abc");

            // Make strongly typed Actor calls with Remoting.
            // DemoActor is the type registered with Dapr runtime in the service.
            var proxy = ActorProxy.Create<IDemoActor>(actorId, "DemoActor");

            try{
                MyData currentData = await proxy.GetData();                
                if(currentData != null){
                    Console.WriteLine("Points: " + currentData.Points + ", Highest Temp: " + currentData.HighestTemp);
                    points = currentData.Points.HasValue ? currentData.Points.Value : 0;
                    if(weatherForecast.TemperatureC > currentData.HighestTemp)
                        highestTemp = weatherForecast.TemperatureC;
                    else highestTemp = currentData.HighestTemp.HasValue ? currentData.HighestTemp.Value : 0;
                }
            }
            catch(Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
            var data = new MyData()
            {
                Points = ++points
            };
          

            Console.WriteLine("Making call using actor proxy to save data.");
            await proxy.SaveData(data);

            return "success";
        }

    }
}
