#!/bin/bash
echo "Test: http://carts.carts-test.$(kubectl get cm keptn-domain -n keptn -ojsonpath={.data.app_domain})"
echo "Hardening: http://carts.carts-hardening.$(kubectl get cm keptn-domain -n keptn -ojsonpath={.data.app_domain})"
echo "Production: http://carts.carts-production.$(kubectl get cm keptn-domain -n keptn -ojsonpath={.data.app_domain})"
