using Microsoft.Extensions.Logging;
using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using System.Threading.Tasks.Dataflow;
using System.Linq;
using adapter_BHYT.Models;  // Thêm namespace cho các model

namespace adapter_BHYT.Services
{
    public class MessageProcessor
    {
        private readonly ILogger<MessageProcessor> _logger;
        private readonly DatabaseService _databaseService;
        private readonly ActionBlock<QueryRequest> _processingBlock;
        private readonly ConcurrentDictionary<string, TaskCompletionSource<QueryResponse>> _pendingRequests;
        private readonly int _maxConcurrentTasks;

        public MessageProcessor(ILogger<MessageProcessor> logger, DatabaseService databaseService, int maxConcurrentTasks = 10)
        {
            _logger = logger;
            _databaseService = databaseService;
            _maxConcurrentTasks = maxConcurrentTasks;
            _pendingRequests = new ConcurrentDictionary<string, TaskCompletionSource<QueryResponse>>();

            // Cấu hình block xử lý với số lượng tác vụ đồng thời tối đa
            var executionOptions = new ExecutionDataflowBlockOptions
            {
                MaxDegreeOfParallelism = _maxConcurrentTasks,
                BoundedCapacity = _maxConcurrentTasks * 2 // Buffer size
            };

            _processingBlock = new ActionBlock<QueryRequest>(
                async request => await ProcessMessageAsync(request),
                executionOptions
            );
        }

        public async Task<QueryResponse> ProcessRequestAsync(QueryRequest request)
        {
            var tcs = new TaskCompletionSource<QueryResponse>();
            if (!_pendingRequests.TryAdd(request.QueryId!, tcs))
            {
                throw new InvalidOperationException($"Yêu cầu với ID {request.QueryId} đã tồn tại");
            }

            try
            {
                // Gửi request vào queue xử lý
                await _processingBlock.SendAsync(request);
                
                // Chờ kết quả với timeout
                using var cts = new CancellationTokenSource(TimeSpan.FromMinutes(5)); // 5 phút timeout
                using var registration = cts.Token.Register(() => 
                    tcs.TrySetCanceled(cts.Token));

                return await tcs.Task;
            }
            finally
            {
                _pendingRequests.TryRemove(request.QueryId!, out _);
            }
        }

        private async Task ProcessMessageAsync(QueryRequest request)
        {
            try
            {
                _logger.LogInformation("Bắt đầu xử lý yêu cầu {QueryId}", request.QueryId);

                // Thực hiện truy vấn
                var response = await _databaseService.ExecuteQueryAsync(request);

                // Hoàn thành yêu cầu
                if (_pendingRequests.TryGetValue(request.QueryId!, out var tcs))
                {
                    tcs.TrySetResult(response);
                }

                _logger.LogInformation("Hoàn thành xử lý yêu cầu {QueryId}", request.QueryId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi xử lý yêu cầu {QueryId}: {Error}", request.QueryId, ex.Message);
                
                // Trả về lỗi cho yêu cầu
                if (_pendingRequests.TryGetValue(request.QueryId!, out var tcs))
                {
                    var errorResponse = new QueryResponse
                    {
                        QueryId = request.QueryId,
                        Success = false,
                        Message = $"Lỗi: {ex.Message}",
                        Data = new { Error = ex.ToString() }
                    };
                    
                    tcs.TrySetResult(errorResponse);
                }
            }
        }

        public int GetPendingRequestsCount()
        {
            return _pendingRequests.Count;
        }

        public IEnumerable<string> GetPendingRequestIds()
        {
            return _pendingRequests.Keys.ToList();
        }
    }
} 