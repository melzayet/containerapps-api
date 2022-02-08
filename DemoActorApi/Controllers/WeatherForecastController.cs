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
        public IEnumerable<WeatherForecast> Get()
        {
            var rng = new Random();
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateTime.Now.AddDays(index),
                TemperatureC = rng.Next(-20, 55),
                Summary = Summaries[rng.Next(Summaries.Length)]
            })
            .ToArray();
        }

        [HttpPost]
        public async Task<string> SetWeatherData(WeatherForecast weatherForecast)
        {                 
            
            const string storeName = "statestore";
            const string key = "counter";       
            var daprClient = new DaprClientBuilder().Build();
            await daprClient.SaveStateAsync<int>(storeName, key,11);

            var counter = await daprClient.GetStateAsync<int>(storeName, key);

            /*int points =0, highestTemp= 0;

            // Create an actor Id.
            var actorId = new ActorId("abc");

            // Make strongly typed Actor calls with Remoting.
            // DemoActor is the type registered with Dapr runtime in the service.
            var proxy = ActorProxy.Create<IDemoActor>(actorId, "DemoActor");

            MyData currentData = await proxy.GetData();
            if(currentData != null){
                points = currentData.Points.HasValue ? currentData.Points.Value : 0;
                if(weatherForecast.TemperatureC > currentData.HighestTemp)
                    highestTemp = weatherForecast.TemperatureC;
            }
            var data = new MyData()
            {
                Points = points++,
                HighestTemp = highestTemp
            };

            Console.WriteLine("Making call using actor proxy to save data.");
            await proxy.SaveData(data);*/

            return counter.ToString();
        }

    }
}
