# 定义一个目标组，负载均衡器将流量路由到这里
# 目标组是一个逻辑集合，包含所有可接收流量的目标实例(如ECS任务)
# 它自动跟踪哪些实例健康可用，负载均衡器据此分发流量
resource "aws_lb_target_group" "taskoverflow" {
 name = "taskoverflow"       # 目标组名称
 port = 6400                 # 目标实例接收流量的端口
 protocol = "HTTP"           # 使用HTTP协议与目标实例通信
 vpc_id = aws_security_group.taskoverflow.vpc_id  # 在哪个VPC中创建
 target_type = "ip"          # 目标类型为IP地址（适用于Fargate），表示目标组将包含IP地址而非实例ID
 
 # 健康检查配置，用于确定目标组中的实例是否健康
 # 负载均衡器定期检查每个实例，只向健康的实例发送流量
 health_check {
   path = "/api/v1/health"   # 健康检查URL路径，负载均衡器会向此路径发送请求
   port = "6400"             # 健康检查使用的端口
   protocol = "HTTP"         # 健康检查协议
   healthy_threshold = 2     # 连续成功2次视为健康，会开始接收流量
   unhealthy_threshold = 2   # 连续失败2次视为不健康，会停止接收流量
   timeout = 5               # 健康检查请求超时时间（秒）
   interval = 10             # 健康检查间隔时间（秒），每10秒检查一次
 }
}

# 创建应用负载均衡器(ALB)，用于分发流量到目标组中的多个实例
resource "aws_lb" "taskoverflow" {
 name = "taskoverflow"             # 负载均衡器名称
 internal = false                  # 非内部的，即可从外部访问
 load_balancer_type = "application" # 应用负载均衡器类型
 subnets = data.aws_subnets.private.ids  # 部署在哪些子网
 security_groups = [aws_security_group.taskoverflow_lb.id]  # 关联的安全组
}

# 为负载均衡器创建安全组，控制进出流量
resource "aws_security_group" "taskoverflow_lb" {
 name = "taskoverflow_lb"           # 安全组名称
 description = "TaskOverflow Load Balancer Security Group"  # 描述
 
 # 入站规则：允许所有来源的HTTP流量
 ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]      # 允许来自任何IP的访问
 }
 
 # 出站规则：允许所有出站流量
 egress {
   from_port = 0
   to_port = 0
   protocol = "-1"                  # 所有协议
   cidr_blocks = ["0.0.0.0/0"]      # 允许访问任何IP
 }
 
 tags = {
   Name = "taskoverflow_lb_security_group"  # 标签名称
 }
}

# 创建负载均衡器监听器，接收外部请求并转发到目标组
# 监听器监控指定端口上的请求，并根据规则将这些请求路由到目标组
resource "aws_lb_listener" "taskoverflow" {
 load_balancer_arn = aws_lb.taskoverflow.arn  # 关联到哪个负载均衡器
 port = "80"                      # 监听的端口，接收外部HTTP请求
 protocol = "HTTP"                # 使用的协议
 
 # 默认动作：转发请求到目标组
 # 当请求到达监听器时，将按此规则处理
 default_action {
   type = "forward"              # 动作类型为转发，即将请求发送到目标组
   target_group_arn = aws_lb_target_group.taskoverflow.arn  # 转发到哪个目标组
 }
}

# 输出负载均衡器的DNS名称，便于访问服务
output "taskoverflow_dns_name" {
  value = aws_lb.taskoverflow.dns_name          # 获取负载均衡器的DNS名称
  description = "DNS name of the TaskOverflow load balancer."  # 描述此输出的用途
}