public class PerformanceMetrics
{
    public long TotalMessagesProcessed { get; set; }
    public long CurrentActiveConnections { get; set; }
    public TimeSpan AverageProcessingTime { get; set; }
    public int PendingRequests { get; set; }
    public List<string> ActiveRequestIds { get; set; } = new();
} 