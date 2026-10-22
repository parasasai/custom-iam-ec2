pipeline {
    agent any

    // Suppress interactive prompts since it is running via background automation
    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Work') {
            steps {
                // Securely extracts your saved AWS credentials directly into terminal memory
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'aws-credentials-id', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    
                    echo "=== Running Terraform Pipeline ==="
                    
                    echo "Initializing Working Directory..."
                    sh 'terraform init'
                    
                    echo "Creating Infrastructure Preview Plan..."
                    sh 'terraform plan -out=tfplan'
                    
                    // Pauses execution natively inside the credential context block
                    input message: "Review the plan output above. Do you want to deploy this infrastructure to AWS?", 
                          ok: "Deploy Now"
                    
                    echo "Applying Changes to AWS Cloud..."
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }

    post {
        always {
            // Uses the workspace block instead of 'node' to fix the label compilation error
            cleanWs()
        }
    }
}
