using System;
using System.Collections.Generic;

namespace adapter_BHYT.Models
{
    /// <summary>
    /// Đại diện cho một yêu cầu truy vấn từ WebSocket
    /// </summary>
    public class QueryRequest
    {
        private string? _queryId;
        public string? QueryId 
        { 
            get => _queryId;
            set => _queryId = string.IsNullOrEmpty(value) ? Guid.NewGuid().ToString() : value;
        }
        
        public QueryRequest()
        {
            QueryId = Guid.NewGuid().ToString(); // Tự động tạo ID khi khởi tạo
        }

        /// <summary>
        /// ID bệnh nhân
        /// </summary>
        public string? PatientId { get; set; }

        /// <summary>
        /// Số điện thoại bảo hiểm y tế
        /// </summary>
        public string? InsuranceNumber { get; set; }

        /// <summary>
        /// Ngày yêu cầu
        /// </summary>
        public DateTime? RequestDate { get; set; } = DateTime.Now;

        /// <summary>
        /// Loại truy vấn (select, insert, update, delete)
        /// </summary>
        public string? QueryType { get; set; }

        /// <summary>
        /// Câu truy vấn SQL
        /// </summary>
        public string? SqlQuery { get; set; }

        /// <summary>
        /// Tham số cho truy vấn
        /// </summary>
        public Dictionary<string, object>? Parameters { get; set; }

        /// <summary>
        /// Thời gian tạo yêu cầu
        /// </summary>
        public DateTime Timestamp { get; set; } = DateTime.Now;
    }
} 