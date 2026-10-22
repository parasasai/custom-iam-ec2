pipeline {
    agent any

    // Enables a dropdown menu toggle mechanism inside the Jenkins Pipeline user interface
    parameters {
        choice(
            name: 'ACTION', 
            choices: ['Deploy', 'Destroy'], 
            description: 'Select the operational objective for the Sai-DevOps infrastructure cluster.'
        )
    }

    environment {
        // Enforces placement boundary alignment inside your selected AWS Region
        AWS_DEFAULT_REGION = 'eu-central-1'
        // Binds access secrets from your Jenkins Global Credentials Store
        AWS_CREDENTIALS    = credentials('aws-credentials-id') 
    }

    options {
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        // Removed ansiColor('xterm') to fix the compilation error
    }

    stages {
        stage('Checkout Version Control') {
            steps {
                echo 'Pulling configuration repository branches from Git...'
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                echo 'Initializing backend plugins and connecting to the central S3 Remote State bucket...'
                withEnv(["AWS_ACCESS_KEY_ID=${env.AWS_CREDENTIALS_USR}", "AWS_SECRET_ACCESS_KEY=${env.AWS_CREDENTIALS_PSW}"]) {
                    sh 'terraform init'
                }
            }
        }

        stage('Execute Cycle Action Strategy') {
            steps {
                withEnv(["AWS_ACCESS_KEY_ID=${env.AWS_CREDENTIALS_USR}", "AWS_SECRET_ACCESS_KEY=${env.AWS_CREDENTIALS_PSW}"]) {
                    script {
                        // Structural conditional routing engine based on active user parameters
                        if (params.ACTION == 'Deploy') {
                            echo '🚀 Running dry-run validation layout plan...'
                            sh 'terraform plan -out=tfplan'
                            
                            // Safe gate mechanism requiring manual checkpoint sign-off inside the dashboard
                            input message: 'Authorize the deployment of Sai-DevOps infrastructure components?', ok: 'Apply Plan'
                            
                            echo 'Provisioning network topology, compliance IAM profiles, and compute nodes...'
                            sh 'terraform apply -input=false tfplan'
                        } else {
                            echo '⚠️ Generating infrastructure destruction dry-run blueprint summary...'
                            sh 'terraform plan -destroy'
                            
                            // Mandatory safeguard pause checkpoint prior to executing permanent cloud deletions
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
