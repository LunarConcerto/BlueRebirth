using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.Windows;
using System.Windows.Controls;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.ViewModels;

namespace BlueOath.Launcher.Wpf.Views;

public partial class GuardianPage : UserControl
{
    private ObservableCollection<LogEntry>? _currentEntries;

    public GuardianPage()
    {
        InitializeComponent();
        LogListBox.Loaded += OnLogListBoxLoaded;
        DataContextChanged += OnDataContextChanged;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (e.OldValue is GuardianViewModel oldVm)
        {
            oldVm.PropertyChanged -= OnViewModelPropertyChanged;
        }
        if (e.NewValue is GuardianViewModel newVm)
        {
            newVm.PropertyChanged += OnViewModelPropertyChanged;
            AttachToEntries(GetCurrentEntries(newVm));
        }
    }

    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(GuardianViewModel.SelectedLogTab))
        {
            if (DataContext is GuardianViewModel vm)
            {
                AttachToEntries(GetCurrentEntries(vm));
            }
        }
    }

    private static ObservableCollection<LogEntry>? GetCurrentEntries(GuardianViewModel vm)
    {
        return (vm.SelectedLogTab as LogTab)?.Entries;
    }

    private void AttachToEntries(ObservableCollection<LogEntry>? entries)
    {
        if (_currentEntries != null)
        {
            _currentEntries.CollectionChanged -= OnEntriesChanged;
        }
        _currentEntries = entries;
        if (_currentEntries != null)
        {
            _currentEntries.CollectionChanged += OnEntriesChanged;
        }
        ScrollToBottom();
    }

    private void OnEntriesChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        if (e.Action == NotifyCollectionChangedAction.Add)
        {
            ScrollToBottom();
        }
    }

    private void OnLogListBoxLoaded(object sender, RoutedEventArgs e)
    {
        ScrollToBottom();
    }

    private void ScrollToBottom()
    {
        if (_currentEntries is { Count: > 0 })
        {
            LogListBox.ScrollIntoView(_currentEntries[^1]);
        }
    }
}