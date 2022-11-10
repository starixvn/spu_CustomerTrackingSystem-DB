from alertor.alertor import Alertor

alert = Alertor()

alert.CheckBigQuery("master")
alert.CheckBigQuery("replica")