from collector.collector import Collector
from alertor.alertor import Alertor

cll = Collector()
alert = Alertor()



cll.MonitorSPMetric('master')
cll.MonitorSPMetric('replica')
cll.MonitorSPMetric('archive')

cll.MonitorTableMetric('master')
cll.MonitorTableMetric('replica')
cll.MonitorTableMetric('archive')


cll.MonitorIndexMetric('master')
cll.MonitorIndexMetric('replica')
cll.MonitorIndexMetric('archive')

alert.CheckTableScan('master')
alert.CheckTableScan('replica')