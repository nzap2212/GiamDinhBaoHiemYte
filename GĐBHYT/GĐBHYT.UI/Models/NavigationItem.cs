using System;
using System.Collections.Generic;
using MaterialDesignThemes.Wpf;

namespace GĐBHYT.UI.Models
{
    public class NavigationItem
    {
        public PackIconKind Icon { get; set; }
        public string Label { get; set; }
        public Type NavigationType { get; set; }
        public List<NavigationItem> Children { get; set; } = new List<NavigationItem>();
        public bool IsExpanded { get; set; }
    }
} 