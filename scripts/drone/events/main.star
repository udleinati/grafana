load(
    'scripts/drone/utils/utils.star',
    'pipeline',
    'notify_pipeline',
    'failure_template',
    'drone_change_template',
)

load(
    'scripts/drone/pipelines/docs.star',
    'docs_pipelines',
    'trigger_docs_main',
)

load(
    'scripts/drone/pipelines/test_frontend.star',
    'test_frontend',
)

load(
    'scripts/drone/pipelines/test_backend.star',
    'test_backend',
)

load(
    'scripts/drone/pipelines/integration_tests.star',
    'integration_tests',
)

load(
    'scripts/drone/pipelines/build.star',
    'build_e2e',
)

load(
    'scripts/drone/pipelines/windows.star',
    'windows',
)

load(
    'scripts/drone/pipelines/publish.star',
    'publish',
)

load(
    'scripts/drone/pipelines/trigger_downstream.star',
    'enterprise_downstream_pipeline',
)

load('scripts/drone/vault.star', 'from_secret')


ver_mode = 'main'
trigger = {
    'event': ['push',],
    'branch': 'main',
    'paths': {
        'exclude': [
            '*.md',
            'docs/**',
            'latest.json',
        ],
    },
}

def main_pipelines(edition):
    drone_change_trigger = {
        'event': ['push',],
        'branch': 'main',
        'repo': [
            'grafana/grafana',
        ],
        'paths': {
            'include': [
                '.drone.yml',
            ],
            'exclude': [
                'exclude',
            ],
        },
    }

    pipelines = [
        docs_pipelines(edition, ver_mode, trigger_docs_main()),
        test_frontend(trigger, ver_mode),
        test_backend(trigger, ver_mode),
        build_e2e(trigger, ver_mode, edition),
        integration_tests(trigger, ver_mode, edition),
        windows(trigger, edition, ver_mode),
    notify_pipeline(
        name='notify-drone-changes', slack_channel='slack-webhooks-test', trigger=drone_change_trigger,
        template=drone_change_template, secret='drone-changes-webhook',
    ),
    publish(trigger, ver_mode, edition),
    enterprise_downstream_pipeline(edition, ver_mode),
    notify_pipeline(
        name='main-notify', slack_channel='grafana-ci-notifications', trigger=dict(trigger, status=['failure']),
        depends_on=['main-test-frontend', 'main-test-backend', 'main-build-e2e-publish', 'main-integration-tests', 'main-windows', 'main-publish'],
        template=failure_template, secret='slack_webhook'
    )]

    return pipelines
