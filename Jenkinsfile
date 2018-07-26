properties(
	[
		buildDiscarder(
			logRotator(
				artifactDaysToKeepStr: '',
				artifactNumToKeepStr: '',
				daysToKeepStr: '',
				numToKeepStr: '3'
			)
		),
		disableConcurrentBuilds(),
		pipelineTriggers([])
	]
)

node ('cloudbees_slave') {
	checkout scm
	slackSend color: '#4CAF50', channel: '#devops', message: "Started ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>)"
	currentBuild.result = 'SUCCESS'

	try {
		stage("version_text") {
			sh '_devops/scripts/create_version_txt.sh'
		}

        // Push a Docker container (and deploy if required)
        switch(env.BRANCH_NAME) {
            case "master":
                stage("push_container") {
                    sh '_devops/scripts/push_container_all.sh'
                }
                slackSend color: '#4CAF50', channel: '#devops', message: "Completed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) successfully. A new ECS Task is ready to deploy."
                break
       }

	} catch (all) {
		slackSend color: '#f44336', channel: '#devops', message: "Failed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) - <${env.BUILD_URL}console|click here to see the console output>"
		currentBuild.result = 'FAILURE'
	}
}
