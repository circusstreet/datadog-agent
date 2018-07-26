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

        // Test if the site actually builds
        switch(env.BRANCH_NAME) {
            case "DONE_RR":
                stage("compile_site") {
                    sh 'cp _devops/env/.env-prod .env.local'
					sh 'npm install'
					sh 'npm run lint'
					sh 'CI=true npm run test'
					sh 'npm run build'
                }
                break
            case "QA_PASSED":
                stage("compile_site") {
                    sh 'cp _devops/env/.env-stag .env.local'
					sh 'npm install'
					sh 'npm run lint'
					sh 'CI=true npm run test'
					sh 'npm run build'
                }
                break
            case "v0.1.x":
                stage("compile_site") {
                    sh 'cp _devops/env/.env-dev .env.local'
					sh 'npm install'
					sh 'npm run lint'
					sh 'CI=true npm run test'
					sh 'npm run build'
                }
                break
        }

        // Push a Docker container (and deploy if required)
        switch(env.BRANCH_NAME) {
            case "DONE_RR":
                stage("push_container") {
                    sh '_devops/scripts/push_container_production.sh'
                }
                slackSend color: '#4CAF50', channel: '#devops', message: "Completed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) successfully. A new ECS Task is ready to deploy."
                break
            case "QA_PASSED":
                stage("push_container") {
                    sh '_devops/scripts/push_container_staging.sh'
                }
                slackSend color: '#4CAF50', channel: '#devops', message: "Completed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) successfully. Changes will be deployed to https://cobrandingui.stag.circusstreet.com/ within the next few minutes."
                break
            case "v0.1.x":
                stage("push_container") {
                    sh '_devops/scripts/push_container_dev.sh'
                }
                slackSend color: '#4CAF50', channel: '#devops', message: "Completed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) successfully. Changes will be deployed to https://cobrandingui.dev.circusstreet.com/ within the next few minutes."
                break
            default:
                slackSend color: '#4CAF50', channel: '#devops', message: "Completed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) successfully."
        }

	} catch (all) {
		slackSend color: '#f44336', channel: '#devops', message: "Failed ${env.JOB_NAME} (<${env.BUILD_URL}|build ${env.BUILD_NUMBER}>) - <${env.BUILD_URL}console|click here to see the console output>"
		currentBuild.result = 'FAILURE'
	}
}
