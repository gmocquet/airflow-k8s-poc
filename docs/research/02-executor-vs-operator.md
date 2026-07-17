# 02 — Executor vs. Operator

There is a recurring confusion between the **KubernetesExecutor** and the **KubernetesPodOperator**.
They share the "Kubernetes" name because both belong to the Kubernetes ecosystem, but they are
fundamentally different things: one is an **Executor**, the other an **Operator**. Comparing them
directly is a category error — and the distinction has to be clear *before* any architectural
decision.

## Executor — *how* tasks run (cluster-level)

An **Executor** is the mechanism by which task instances get run. Executors share a common API and are
"pluggable" — you swap them based on your installation's needs. An executor is a **cluster-level**
configuration of the Airflow scheduler: it defines how the scheduler dispatches tasks and monitors
their execution. For production workloads this is typically a remote executor (KubernetesExecutor,
CeleryExecutor) where the actual task runs in a separate process or pod, and the scheduler reports
status back to the metadata database.

By default an executor applies **globally**: every task inherits the same base image, the same
resource requests, and the same runtime configuration. You *can* override these per task with
[`executor_config` and its `pod_override`](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/10.19.0/kubernetes_executor.html#pod-override)
attribute — but that is a workaround, not the primary intent of executors.

## Operator — *what* a task does (DAG-level)

An **Operator** is a template for a predefined task that you declare inside your DAG. Think of it as a
framework or SDK that provides pre-built task logic, so you don't implement everything from scratch.
Operators define **what** a task does, at the **DAG level** — and, crucially, **an operator works with
any executor**.

## Summary

| | Executor | Operator |
| --- | --- | --- |
| Answers | **How** tasks are dispatched & monitored | **What** a task does |
| Scope | Cluster-level (scheduler configuration) | DAG-level (per task) |
| Examples | Kubernetes, Celery, Local | KubernetesPodOperator, PythonOperator, BashOperator |
| Interchangeable? | No — different layers, not directly comparable | |

In short: an **Executor** controls *how* tasks are dispatched and monitored (cluster-level); an
**Operator** controls *what* a task does (DAG-level). These are not interchangeable concepts and
should not be compared directly.

## The KubernetesPodOperator does not require the KubernetesExecutor

A common misconception is that the KubernetesPodOperator only works under the KubernetesExecutor. It
does not. The KPO runs under any of the following executors:

- Local executor
- Celery executor
- Kubernetes executor

> The `LocalKubernetesExecutor` and `CeleryKubernetesExecutor` (hybrid executors) were **removed in
> Airflow 3.0.0** and are no longer available.

Which executor you pair with the KPO has direct consequences on how many pods each task creates — the
subject of [the next document](03-kubernetes-executor-meets-kpo.md).

---

## Further resources

**📺 Video — [Deep dive into Airflow Kubernetes Pod Operator vs Executor](https://www.youtube.com/watch?v=b1gpbGB058M)**
· MaxcoTec Learning · ~12 min

[![Deep dive into Airflow Kubernetes Pod Operator vs Executor — MaxcoTec Learning (opens on YouTube)](https://img.youtube.com/vi/b1gpbGB058M/maxresdefault.jpg)](https://www.youtube.com/watch?v=b1gpbGB058M)

A focused walkthrough of the same distinction covered above: what the KubernetesPodOperator is, how it
differs from the KubernetesExecutor, when you actually need the KPO, and three ways to pass context
into the launched pod (image arguments, environment variables, and Kubernetes ConfigMaps).

Chapter timeline:

| Time | Chapter |
| --- | --- |
| 00:00 | Intro |
| 01:05 | Kubernetes pods |
| 01:36 | KubernetesPodOperator |
| 02:17 | KubernetesExecutor reference |
| 02:40 | KubernetesPodOperator vs. KubernetesExecutor |
| 04:35 – 06:02 | Executor vs. Operator — comparison examples |
| 07:10 | Why you may need the KubernetesPodOperator |
| 09:48 | Passing variables into the KubernetesPodOperator |
| 10:14 / 10:36 / 10:45 | …via image args / env vars / ConfigMaps |
| 11:50 | Outro |

*Summary compiled from the video's title, description, and chapter markers — the video exposes no
transcript/subtitles.*
