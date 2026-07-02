scp /Users/jinma63/project/gpu_commander/jwm_configs/gpu-commander-jwm.service custodian@ferragon:/tmp/
# can not scp to /etc/systemd/system/ directly, it's owned by root.
ssh custodian@ferragon
sudo cp /tmp/gpu-commander-jwm.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gpu-commander-jwm.service
sudo systemctl start gpu-commander-jwm.service
