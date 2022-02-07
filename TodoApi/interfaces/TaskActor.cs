using Dapr.Actors;
using System.Threading.Tasks;

namespace MyActor.Interfaces
{
    public interface IMyActor : IActor
    {       
        Task<string> SetDataAsync(string data);
        Task<TaskData> GetDataAsync();
        Task RegisterReminder();
        Task UnregisterReminder();
        Task RegisterTimer();
        Task UnregisterTimer();
    }

    public class TaskData
    {
        public int? TasksCount { get; set; }
        public string? LastTaskId { get; set; }

        public override string ToString()
        {
            var tasksCount = this.TasksCount == null ? 0 : this.TasksCount;
            var lastTaskId = this.LastTaskId == "" ? "-" : this.LastTaskId;

            return $"TasksCount: {tasksCount}, LastTaskId: {lastTaskId}";
        }
    }
}