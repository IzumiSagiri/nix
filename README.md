這是我的nixos系統設置，在這裏加一點說明：

1. 如何更新，推薦每日更新
在你存放nix系統配置文件的文件夾：
sudo nix flake update
sudo nixos-rebuild switch --flake .

安全提醒：我一般採用unstable頻道，但是有一個例外，那就是ungoogled-chromium。這是因爲nixos由於其運行機制，當chromium內核出現重大安全漏洞時，他們只patch stable頻道的版本。因此不推薦在unstable頻道上裝ungoogle-chromium。

2. 如何清理系統垃圾
   雖然我的設置已經內置了定期清理垃圾
   sudo nix-collect-garbage -d
