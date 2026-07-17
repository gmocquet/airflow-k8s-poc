# Research & Theory — Airflow on Kubernetes

This folder is the **why** behind the repository's **what** and **how**. The root
[`README.md`](../../README.md) shows the running proof-of-concept — the code, the local Kubernetes
stack, and the commands to reproduce it. The documents here capture the **theoretical study** and the
**conclusions** that led to the design: why this PoC pairs the **KubernetesExecutor** with the
**KubernetesPodOperator (KPO)**, what that combination actually costs at the pod level, and where the
architecture should go next.

> **Provenance.** These notes distill first-hand research and local experimentation into a
> vendor-neutral write-up. Company-, team-, and project-specific details are intentionally
> generalized so the reasoning stands on its own.

## Contents

| # | Document | What it covers |
| --- | --- | --- |
| 01 | [Airflow core concepts](01-airflow-core-concepts.md) | What Airflow is, when it fits, and its component architecture. |
| 02 | [Executor vs. Operator](02-executor-vs-operator.md) | The recurring confusion between the two, with precise definitions. |
| 03 | [KubernetesExecutor meets KubernetesPodOperator](03-kubernetes-executor-meets-kpo.md) | The 2-pods-per-task result — theory, official-doc anchors, and a local experiment. |
| 04 | [Executor & Operator strategy](04-executor-strategy.md) | CeleryExecutor + KPO + KEDA, the decision matrix, and conclusions. |

## Reading order

Start at **01** for the vocabulary, read **02** to stop conflating the two Kubernetes-named
components, then **03** for the core finding, and **04** for the strategy that follows from it.

## External sources

- Apache Airflow documentation (pinned **3.2.2**) — <https://airflow.apache.org/docs/apache-airflow/3.2.2/>
- `apache-airflow-providers-cncf-kubernetes` **10.19.0** (the version this repo pins) —
  <https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/10.19.0/index.html>
- Astronomer — Use the KubernetesPodOperator —
  <https://www.astronomer.io/docs/learn/kubepod-operator/>
- Airflow Helm chart (pinned **1.22.0**) — Autoscaling with KEDA —
  <https://airflow.apache.org/docs/helm-chart/1.22.0/keda.html>
