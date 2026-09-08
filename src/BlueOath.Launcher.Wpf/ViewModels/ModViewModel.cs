using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows.Input;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf.ViewModels;

public class ModViewModel : ViewModelBase
{
    private readonly ModService _modService;
    private readonly MainViewModel _mainViewModel;
    private ObservableCollection<ModInfo> _mods = new();
    private ModInfo? _selectedMod;

    public ObservableCollection<ModInfo> Mods
    {
        get => _mods;
        set => SetProperty(ref _mods, value);
    }

    public ModInfo? SelectedMod
    {
        get => _selectedMod;
        set => SetProperty(ref _selectedMod, value);
    }

    public ICommand RefreshCommand { get; }
    public ICommand BackCommand { get; }
    public ICommand ToggleModCommand { get; }
    public ICommand ToggleSelectedModCommand { get; }

    public ModViewModel(ModService modService, MainViewModel mainViewModel)
    {
        _modService = modService;
        _mainViewModel = mainViewModel;

        RefreshCommand = new RelayCommand(Refresh);
        BackCommand = new RelayCommand(() => _mainViewModel.NavigateTo(0));
        ToggleModCommand = new RelayCommand<ModInfo>(ToggleMod);
        ToggleSelectedModCommand = new RelayCommand(ToggleSelectedMod, () => SelectedMod is not null);

        Refresh();
    }

    private void ToggleMod(ModInfo mod)
    {
        if (mod is null) return;
        _modService.SetEnabled(mod, !mod.Enabled);
        RefreshPreserveSelection(mod.Id);
    }

    private void ToggleSelectedMod()
    {
        if (SelectedMod is null) return;
        _modService.SetEnabled(SelectedMod, !SelectedMod.Enabled);
        RefreshPreserveSelection(SelectedMod.Id);
    }

    private void RefreshPreserveSelection(string selectedId)
    {
        var loaded = _modService.LoadMods();
        Mods = new ObservableCollection<ModInfo>(loaded);
        SelectedMod = Mods.FirstOrDefault(m => m.Id == selectedId) ?? Mods.FirstOrDefault();
    }

    private void Refresh()
    {
        var loaded = _modService.LoadMods();
        Mods = new ObservableCollection<ModInfo>(loaded);
        SelectedMod = Mods.FirstOrDefault();
    }
}