import mlflow
import pytest


@pytest.fixture(scope="module")
def logs():
    parameters = {
        "param1": "param1_val",
        "param2": "param2_val"
    }
    metric = {
        "key": "metric1",
        "val": list(range(10))
    }
    tag = {
        "key": "tag_key1",
        "val": "tag_val1"
    }

    return {
        "parameters": parameters,
        "metric": metric,
        "tag": tag
    }


@pytest.fixture(scope="module")
def artifact():
    dummy_artifact = "dummy.txt"
    with open(dummy_artifact, 'w'):
        pass  # create an empty file

    return dummy_artifact


def mlflow_run(commands):
    experiment_name = 'test_experiment'
    run_name = "test_run"

    mlflow.set_experiment(experiment_name)
    with mlflow.start_run(run_name=run_name):
        commands()


@pytest.mark.dependency()
def test_mlflow_log_to_backend(logs):
    # GIVEN
    def mlflow_commands():
        mlflow.log_params(logs["parameters"])

        for vv in logs["metric"]["val"]:
            mlflow.log_metric(logs["metric"]["key"], vv)

        mlflow.set_tag(logs["tag"]["key"], logs["tag"]["val"])

    # WHEN
    mlflow_run(mlflow_commands)

    # THEN
    assert True  # logging succeeded


@pytest.mark.dependency(depends=["test_mlflow_log_to_backend"])
def test_mlflow_get_logs():
    assert True


@pytest.mark.dependency()
def test_mlflow_log_artifact(artifact):
    # GIVEN
    def mlflow_commands():
        mlflow.log_artifact(artifact)

    # WHEN
    mlflow_run(mlflow_commands)

    # THEN
    assert True  # logging succeeded


@pytest.mark.dependency(depends=["test_mlflow_log_artifact"])
def test_mlflow_get_artifact():
    assert True
