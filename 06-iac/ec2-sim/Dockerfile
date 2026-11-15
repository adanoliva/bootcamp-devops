FROM amazonlinux:2023

RUN dnf install -y openssh-server sudo shadow-utils procps-ng && dnf clean all \
 && useradd -m ec2-user && usermod -p '*' ec2-user \
 && echo "ec2-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ec2-user \
 && ssh-keygen -A

EXPOSE 22 80

CMD ["sh", "-c", "install -d -m 700 -o ec2-user -g ec2-user /home/ec2-user/.ssh && install -m 600 -o ec2-user -g ec2-user /tmp/key.pub /home/ec2-user/.ssh/authorized_keys && exec /usr/sbin/sshd -D -e"]
