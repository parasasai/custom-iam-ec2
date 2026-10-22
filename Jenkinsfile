pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION', 
            choices: ['Deploy', 'Destroy'], 
            description: 'Select the operational objective for the Sai-DevOps infrastructure cluster.'
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
        stage('Checkout Version Control') {
            steps {
                echo 'Pulling configuration repository branches from Git...'
                checkout scm
            }
        }

        stage('Execute Cycle Action Strategy') {
            steps {
                // FIX: Universal usernamePassword strategy pulls the access key and secret key out of your exact 'aws-credentials-id' item natively
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials-id', 
                    usernameVariable: 'AWS_ACCESS_KEY_ID', 
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        echo 'Initializing backend plugins and connecting to the central S3 Remote State bucket...'
                        sh 'terraform init'

                        if (params.ACTION == 'Deploy') {
                            echo '🚀 Running dry-run validation layout plan...'
                            sh 'terraform plan -out=tfplan'
                            
                            input message: 'Authorize the deployment of Sai-DevOps infrastructure components?', ok: 'Apply Plan'
                            
                            echo 'Provisioning network topology, compliance IAM profiles, and compute nodes...'
                            sh 'terraform apply -input=false tfplan'
                        } else {
                            echo '⚠️ Generating infrastructure destruction dry-run blueprint summary...'
                            sh 'terraform plan -destroy'
                            
                            input message: 'CRITICAL WARNING: Are you absolutely certain you want to PERMANENTLY DESTROY the environment?', ok: 'Confirm Destruction'
                            
                            echo '💥 Tearing down active cloud components from S3 state records...'
                            sh 'terraform destroy -auto-approve'
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
