using System;
using System.Collections.Generic;

namespace adapter_BHYT.Models
{
    public class ConfigResult
    {
        public Dictionary<string, string> ConfigItems { get; set; } = new Dictionary<string, string>();
        public DateTime LastUpdated { get; set; } = DateTime.Now;
    }
} 