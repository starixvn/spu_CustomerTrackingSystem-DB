import sys
import datetime
import json
from neo4j_migration.model_bootstrap import Neo4jContext, DEFAULT_DATABASE
from neo4j_migration.nodes import Device,NodeEncoder

class AssociationByDeviceRun(Neo4jContext):
    def __init__(self, label="Device",database=DEFAULT_DATABASE):
        super().__init__(label, database)

    @classmethod
    def single_query(cls, tx, keyID:int):
        select_query = """
            MATCH (n:Device {DeviceID:$DeviceID})
            RETURN n.DeviceID AS DeviceID, n.CreatedDate as CreatedDate
            """

        result = tx.run(select_query, DeviceID=keyID)
        nodes = []
        nodes = [Device(row["DeviceID"]
                        , row["CreatedDate"]) for row in result]

        if len(nodes) > 0:
            return nodes.pop()

        return None

    @classmethod
    def create_batch(cls, tx, items:list):
        raws = json.dumps(items, cls=NodeEncoder)
        batch = json.loads(raws)
        create_bulk = """
            UNWIND $batch as row
            MERGE (n:Device {DeviceID:toInteger(row.DeviceID)})
            ON CREATE SET n.DeviceID=toInteger(row.DeviceID)
                , n.CreatedDate=datetime(row.CreatedTime)
            ON MATCH SET n.LastAssDate=datetime(row.CreatedTime)
            RETURN ID(n) as NID
            """
        # node first
        n_result = tx.run(create_bulk,batch=batch)
        nIDs = [row["NID"] for row in n_result]

        # relationship
        used_device = """
            UNWIND $batch as row
            MATCH (c:CTSCustomer {CTSCustID:toInteger(row.CTSCustID)})
            MATCH (n:Device {DeviceID:toInteger(row.DeviceID)})
            WHERE row.CTSCustID > 0 AND row.DeviceID > 0
            MERGE (c)-[r:USED_DEVICE]-(n)
            ON CREATE SET r.CreatedTime = datetime(row.CreatedTime)
            RETURN ID(r) AS RID
            """
        r_result = tx.run(used_device,batch=batch)

        return nIDs

    @classmethod
    def update_batch(cls, tx, items:list):
        raws = json.dumps(items, cls=NodeEncoder)
        batch = json.loads(raws)
        # add relationship
        rIDs=None
        used_device = """
            UNWIND $batch as row
            MATCH (c:CTSCustomer {CTSCustID:toInteger(row.CTSCustID)})
            MERGE (n:Device {DeviceID:toInteger(row.DeviceID)})
            MERGE (c)-[r:USED_DEVICE]-(n)
            ON CREATE SET r.CreatedTime=datetime(row.CreatedTime)
                ,n.CreatedDate=datetime(row.CreatedTime)
            ON MATCH SET r.CreatedTime=datetime(row.CreatedTime)
            RETURN ID(r) AS RID
            """
        r_result = tx.run(used_device,batch=batch)
        nIDs = [row["RID"] for row in r_result]

        return rIDs

    @classmethod
    def delete_batch(cls, tx, items:list):
        raws = json.dumps(items, cls=NodeEncoder)
        batch = json.loads(raws)
        # remove AIO
        remove_all = """
            UNWIND $batch as row
            MATCH (n:Device {DeviceID:toInteger(row.DeviceID)})
            DETACH DELETE n
            """
        tx.run(remove_all,batch=batch)

    #binlog processing
    @classmethod
    def create_binlog(cls, tx, raws:list):
        batch = [Device(r["after"]["DCSDeviceID"],r["after"]["CTSCustID"],r["after"]["CreatedTime"]) for r in rows]
        cls.create_batch(tx, batch)

    @classmethod
    def update_binlog(cls, tx, raws:list):
        batch = [Device(r["after"]["DCSDeviceID"],r["after"]["CTSCustID"],r["after"]["CreatedTime"]) for r in rows]
        cls.update_batch(tx, batch)

    @classmethod
    def delete_binlog(cls, tx, raws:list):
        batch = [Device(r["before"]["DCSDeviceID"]) for r in rows]
        cls.delete_batch(tx, batch)
