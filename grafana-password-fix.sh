#!/bin/bash

echo "🔧 Grafana Password Fix Script"
echo "=============================="

# Function to reset Grafana password
reset_grafana_password() {
    echo "📝 Resetting Grafana admin password..."
    kubectl exec -it prometheus-grafana-65cfd7744f-lhbx7 -- grafana-cli admin reset-admin-password admin123
    if [ $? -eq 0 ]; then
        echo "✅ Password reset successful!"
    else
        echo "❌ Password reset failed!"
        return 1
    fi
}

# Function to check if Grafana pod is running
check_grafana_pod() {
    echo "🔍 Checking Grafana pod status..."
    POD_NAME=$(kubectl get pods | grep grafana | awk '{print $1}')
    if [ -z "$POD_NAME" ]; then
        echo "❌ No Grafana pod found!"
        return 1
    fi
    echo "✅ Found Grafana pod: $POD_NAME"
    return 0
}

# Function to start port-forwarding
start_port_forward() {
    echo "🌐 Starting port-forward for Grafana..."
    echo "   Grafana will be available at: http://localhost:3001"
    echo "   Login credentials: admin / admin123"
    echo ""
    echo "Press Ctrl+C to stop port-forwarding"
    kubectl port-forward svc/prometheus-grafana 3001:80
}

# Main execution
echo "🚀 Starting Grafana password fix..."

# Check if Grafana pod is running
if ! check_grafana_pod; then
    echo "❌ Cannot proceed - Grafana pod not found"
    exit 1
fi

# Reset password
if ! reset_grafana_password; then
    echo "❌ Failed to reset password"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo "=================="
echo "📋 Next steps:"
echo "1. Open http://localhost:3001 in your browser"
echo "2. Login with: admin / admin123"
echo "3. The password should now persist across restarts"
echo ""
echo "💡 To start port-forwarding, run:"
echo "   kubectl port-forward svc/prometheus-grafana 3001:80"
echo ""
echo "🔧 If password gets reset again, run this script:"
echo "   ./grafana-password-fix.sh" 