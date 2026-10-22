pipeline {
    agent any

    // Enables structural parameterized options inside Jenkins UI dashboard view
    parameters {
        choice(
            name: 'ACTION', 
            choices: ['Deploy', 'Destroy'], 
            description: 'Select the operational target for the cloud cluster environment.'
        )
        string(
            name: 'S3_BUCKET', 
            defaultValue: 'sai-devops-remote-state-bucket', 
            description: 'The AWS S3 target bucket tracking the remote state file.'
        )
        string(
            name: 'S3_KEY', 
            defaultValue: 'sai-devops/infrastructure/terraform.tfstate', 
            description: 'The directory path key path location mapping within the target S3 storage.'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'eu-central-1'
    }

    options {
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Project Code') {
            steps {
                echo 'Pulling global architecture files from Git version control branch...'
                checkout scm
            }
        }

        stage('Execute Pipeline Action Workflow') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        echo 'Initializing backend storage connectivity and resolving provider plugins...'
                        // Dynamically injects bucket configurations, bypassing static main.tf limitations
                        sh "export TF_IN_AUTOMATION=true && terraform init -input=false " +
                           "-backend-config='bucket=${params.S3_BUCKET}' " +
                           "-backend-config='key=${params.S3_KEY}' " +
                           "-backend-config='region=eu-central-1' " +
                           "-backend-config='encrypt=true' " +
                           "-backend-config='use_lockfile=true'"

                        if (params.ACTION == 'Deploy') {
                            echo '🚀 Running dry-run validation layout plan generation phase...'
                            sh 'export TF_IN_AUTOMATION=true && terraform plan -input=false -out=tfplan'
                            
                            input message: 'Authorize provisioning the infrastructure components to AWS?', ok: 'Apply Plan'
                            
                            echo 'Executing live orchestration deployment...'
                            sh 'export TF_IN_AUTOMATION=true && terraform apply -input=false tfplan'
                        } else {
                            echo '⚠️ Generating infrastructure destruction dry-run blueprint summary...'
                            sh 'export TF_IN_AUTOMATION=true && terraform plan -destroy -input=false'
                            
                            input message: 'CRITICAL WARNING: Are you absolutely certain you want to PERMANENTLY DESTROY the environment?', ok: 'Confirm Destruction'
                            
                            echo '💥 Tearing down active cloud components from S3 state records...'
                            sh 'export TF_IN_AUTOMATION=true && terraform destroy -input=false -auto-approve'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Wiping temporal plan snapshot artifacts and clearing workspace execution caches...'
            sh 'rm -f tfplan'
            cleanWs()
        }
        success {
            echo '🎉 Complete orchestration lifecycle task finalized successfully!'
        }
        failure {
            echo '❌ Automation process run broke. Inspect stage execution logs above for diagnostic reviews.'
        }
    }
}
