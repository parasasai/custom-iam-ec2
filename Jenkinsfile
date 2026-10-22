pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION', 
            choices: ['Deploy', 'Destroy'], 
            description: 'Select the operational objective for the Sai-DevOps infrastructure cluster.'
        )
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

        stage('Terraform Infrastructure Management') {
            steps {
                // Using the native withAWS steps wrapper pointing directly to your stored credentials ID
                withAWS(credentials: 'aws-credentials-id', region: 'eu-central-1') {
                    script {
                        echo 'Initializing backend plugins and connecting to the central S3 Remote State bucket...'
                        sh 'terraform init'

                        if (params.ACTION == 'Deploy') {
                            echo '🚀 Running dry-run validation layout plan...'
                            sh 'terraform plan -out=tfplan'
                            
                            // Safe checkpoint requiring physical manual authorization inside Jenkins UI
                            input message: 'Authorize the deployment of Sai-DevOps infrastructure components?', ok: 'Apply Plan'
                            
                            echo 'Provisioning network topology, compliance IAM profiles, and compute nodes...'
                            sh 'terraform apply -input=false tfplan'
                        } else {
                            echo '⚠️ Generating infrastructure destruction dry-run blueprint summary...'
                            sh 'terraform plan -destroy'
                            
                            // Safeguard pause checkpoint prior to executing permanent cloud deletions
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
