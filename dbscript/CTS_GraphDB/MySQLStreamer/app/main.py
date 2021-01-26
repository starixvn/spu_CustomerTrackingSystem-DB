import sys
import time
import threading
from server import BinlogFactory
from monitoring import run_monitoring
from multiprocessing import shared_memory

act=str(sys.argv[1])
if not act:
    act = 'start'

if __name__ == '__main__':
    try:
       t = threading.Thread(target=run_monitoring, args = ('Thread - run_monitoring', 1, ), daemon=True)
       t.start()
    except Exception as ex:
       sys.stderr.write('%%Error: (%s) unable to start thread.' %str(ex))

    cts_shm = shared_memory.ShareableList([str('6f78a381-5583-11eb-bc7d-0242ac170002:100000000000'),str('2021-01-14 21:24:59'),0],name='cts_shm')
    #print('cts_shm %s' %str(cts_shm.shm.name))
    while True:
        BinlogFactory.process(act)
        time.sleep(300)
    