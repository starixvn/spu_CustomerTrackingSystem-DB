from collector.collector import Collector
from alertor.alertor import Alertor

cll = Collector()
alert = Alertor()

cll.MonitorSPMetric('master')
cll.MonitorSPMetric('replica')
cll.MonitorSPMetric('archive')

cll.MonitorTableMetric('master')
cll.MonitorIndexMetric('master')

cll.MonitorTableMetric('replica')
cll.MonitorIndexMetric('replica')

cll.MonitorTableMetric('archive')
cll.MonitorIndexMetric('archive')


alert.CheckTableScan('archive')
