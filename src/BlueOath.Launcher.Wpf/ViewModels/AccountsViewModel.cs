using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Input;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf.ViewModels;

public sealed class AccountsViewModel : ViewModelBase
{
    private readonly AccountService _accountService;
    private AccountProfile? _selectedAccount;
    private string _newAccountName = "";
    private string _editAccountName = "";

    public ObservableCollection<AccountProfile> Accounts => _accountService.Accounts;
    public AccountProfile ActiveAccount => _accountService.ActiveAccount;
    public string ActiveAccountText => $"当前账号：{ActiveAccount.Name}";

    public AccountProfile? SelectedAccount
    {
        get => _selectedAccount;
        set
        {
            if (!SetProperty(ref _selectedAccount, value)) return;
            EditAccountName = value?.Name ?? "";
            CommandManager.InvalidateRequerySuggested();
        }
    }

    public string NewAccountName
    {
        get => _newAccountName;
        set => SetProperty(ref _newAccountName, value);
    }

    public string EditAccountName
    {
        get => _editAccountName;
        set => SetProperty(ref _editAccountName, value);
    }

    public ICommand AddCommand { get; }
    public ICommand RenameCommand { get; }
    public ICommand RemoveCommand { get; }
    public ICommand SetActiveCommand { get; }

    public AccountsViewModel(AccountService accountService)
    {
        _accountService = accountService;
        _selectedAccount = accountService.ActiveAccount;
        _editAccountName = _selectedAccount.Name;

        AddCommand = new RelayCommand(AddAccount);
        RenameCommand = new RelayCommand(RenameAccount, () => SelectedAccount is not null);
        RemoveCommand = new RelayCommand(RemoveAccount,
            () => SelectedAccount is not null && Accounts.Count > 1);
        SetActiveCommand = new RelayCommand(SetActive,
            () => SelectedAccount is not null && !ReferenceEquals(SelectedAccount, ActiveAccount));

        _accountService.ActiveAccountChanged += (_, _) =>
        {
            OnPropertyChanged(nameof(ActiveAccount));
            OnPropertyChanged(nameof(ActiveAccountText));
            CommandManager.InvalidateRequerySuggested();
        };
    }

    private void AddAccount() => ExecuteAccountChange(() =>
    {
        SelectedAccount = _accountService.Add(NewAccountName);
        NewAccountName = "";
    });

    private void RenameAccount() => ExecuteAccountChange(() =>
    {
        _accountService.Rename(SelectedAccount!, EditAccountName);
        OnPropertyChanged(nameof(ActiveAccountText));
    });

    private void SetActive() => ExecuteAccountChange(() => _accountService.Select(SelectedAccount!));

    private void RemoveAccount()
    {
        if (SelectedAccount is null) return;
        var result = MessageBox.Show(
            $"从启动器中移除账号“{SelectedAccount.Name}”？\n\n游戏存档不会被删除。",
            "移除账号", MessageBoxButton.YesNo, MessageBoxImage.Warning);
        if (result != MessageBoxResult.Yes) return;

        AccountProfile removed = SelectedAccount;
        ExecuteAccountChange(() =>
        {
            _accountService.Remove(removed);
            SelectedAccount = ActiveAccount;
        });
    }

    private static void ExecuteAccountChange(Action action)
    {
        try
        {
            action();
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "账号管理", MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }
}
