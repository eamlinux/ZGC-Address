> 在windows10开机启动时连接openvpn，这应该是最简单的方法了。  
> 在windows 10启动目录中  
```
C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp
```
> 添加快捷方式  
```
"C:\Program Files\OpenVPN\bin\openvpn-gui.exe" --connect client.ovpn
```
> 完成!
