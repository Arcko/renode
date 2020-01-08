*** Settings ***
Library                       Process
Library                       Dialogs
Suite Setup                   Run Keywords
...                           Setup  AND
...                           Run Process  sudo  modprobe  vhci_hcd
Suite Teardown                Teardown
Test Setup                    Run Keywords
...                           Reset Emulation  AND
...                           Run Process  sudo  usbip  detach  -p  0  AND
...                           Sleep  3
Resource                      ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command           mach create
    Execute Command           machine LoadPlatformDescription @${CURDIR}/foboot2.repl
    Execute Command           sysbus LoadELF @https://antmicro.com/projects/renode/fomu--tinyusb_cdc-modified.elf-s_45464-233c6f34a4e669ef9b4533665f437bc061125cba

    Execute Command           emulation CreateUSBIPServer
    Execute Command           host.usb Register sysbus.usb

*** Test Cases ***
Should List TinyUSB CDC/ACM example
    Create Machine
    Start Emulation

    ${output}=  Run Process    sudo  usbip  list  -r  127.0.0.1
    Should Contain             ${output.stdout}  1-0
    Should Contain             ${output.stdout}  cafe:4003
    Should Contain             ${output.stdout}  ef/02/01

Should Enumerate CDC device
    Create Machine

    Start Emulation

    # clear the ring buffer
    Run Process                sudo  dmesg -C

    Run Process                sudo  usbip  attach  -r  127.0.0.1  -d  1-0
    Sleep                      5

    ${output}=  Run Process    sudo  dmesg

    Should Contain             ${output.stdout}  New USB device found, idVendor=cafe, idProduct=4003, bcdDevice= 1.00
    Should Contain             ${output.stdout}  New USB device strings: Mfr=1, Product=2, SerialNumber=3
    Should Contain             ${output.stdout}  Product: TinyUSB Device
    Should Contain             ${output.stdout}  Manufacturer: TinyUSB
    Should Contain             ${output.stdout}  SerialNumber: 123456
    Should Contain             ${output.stdout}  ttyACM0: USB ACM device

Should Communicate With CDC device
    Create Machine

    Start Emulation

    Run Process                sudo  usbip  attach  -r  127.0.0.1  -d  1-0
    Sleep                      5

    ${output}=  Run Process      sudo picocom -qx 5000 -t "ping" /dev/ttyACM0     alias=picocom_process  shell=True

    Should Contain             ${output.stdout}  TinyUSB CDC MSC device example
    Should Contain             ${output.stdout}  ping

