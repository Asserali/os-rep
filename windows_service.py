"""
Windows Agent Service - Runs monitor_windows.py as a Windows Service
This allows the monitoring to run in the background automatically
"""

import win32serviceutil
import win32service
import win32event
import servicemanager
import socket
import sys
import os
import time
import subprocess

class SystemMonitorService(win32serviceutil.ServiceFramework):
    _svc_name_ = "SystemMonitor"
    _svc_display_name_ = "System Monitor Agent"
    _svc_description_ = "Collects system metrics and writes to JSON file"

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)
        self.is_running = True
        
        # Get the directory where the service is installed
        self.service_dir = os.path.dirname(os.path.abspath(__file__))
        self.monitor_script = os.path.join(self.service_dir, 'monitor_windows.py')

    def SvcStop(self):
        """Called when the service is asked to stop"""
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)
        self.is_running = False

    def SvcDoRun(self):
        """Called when the service is started"""
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, '')
        )
        self.main()

    def main(self):
        """Main service loop"""
        while self.is_running:
            try:
                # Run the monitoring script
                subprocess.run(
                    [sys.executable, self.monitor_script],
                    cwd=self.service_dir,
                    capture_output=True,
                    timeout=10
                )
                
                # Wait 5 seconds before next collection
                if win32event.WaitForSingleObject(self.hWaitStop, 5000) == win32event.WAIT_OBJECT_0:
                    break
                    
            except Exception as e:
                servicemanager.LogErrorMsg(f"Error in monitoring loop: {str(e)}")
                time.sleep(5)

if __name__ == '__main__':
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(SystemMonitorService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(SystemMonitorService)
