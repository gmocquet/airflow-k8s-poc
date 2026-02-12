from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator

DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "retries": 0,
    "retry_delay": timedelta(minutes=1),
}

# Image built via `make build-apps` and loaded into kind via `make load-apps`
KPO_POC_IMAGE = "k8s_kpo_poc:local"
NAMESPACE = "airflow"

with DAG(
    dag_id="k8s_kpo_poc",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo", "kubernetes", "kop-poc"],
) as dag:

    # Each KubernetesPodOperator spins up exactly one pod. With two tasks
    # below, a full DAG run will create two pods sequentially (one per task).

    def announce() -> None:
        print("Starting KubernetesPodOperator PoC run: this task does not create a pod.")

    announce_start = PythonOperator(
        task_id="announce_start",
        python_callable=announce,
    )

    greet_airflow = KubernetesPodOperator(
        task_id="greet_airflow",
        name="greet-airflow-kpo",
        namespace=NAMESPACE,
        image=KPO_POC_IMAGE,
        cmds=["k8s-kpo-poc", "hello"],
        image_pull_policy="IfNotPresent",
        on_finish_action="keep_pod",
        get_logs=True,
        labels={
            "airflow.apache.org/component": "task",
            "dag_id": "k8s_kpo_poc",
        },
    )

    sleep_and_log = KubernetesPodOperator(
        task_id="sleep_and_log",
        name="sleep-and-log-kpo",
        namespace=NAMESPACE,
        image=KPO_POC_IMAGE,
        cmds=["k8s-kpo-poc", "sleep", "--seconds", "20"],
        image_pull_policy="IfNotPresent",
        on_finish_action="keep_pod",
        get_logs=True,
        labels={
            "airflow.apache.org/component": "task",
            "dag_id": "k8s_kpo_poc",
        },
    )

    announce_start >> greet_airflow >> sleep_and_log
