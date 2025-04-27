# 定义自动扩展目标 - 指定哪个服务可以自动扩展以及扩展范围
resource "aws_appautoscaling_target" "taskoverflow" {
 max_capacity = 4      # 最大容量，最多扩展到4个实例
 min_capacity = 1      # 最小容量，至少保持1个实例
 
 # 要扩展的资源ID，采用三段式格式："service/[集群名称]/[服务名称]"
 # - "service" 表示这是ECS服务类型
 # - 第一个"taskoverflow"是ECS集群名称
 # - 第二个"taskoverflow"是ECS服务名称
 # 这行明确指定了要扩展的具体ECS服务
 resource_id = "service/taskoverflow/taskoverflow"
 
 # 扩展维度，指定要调整的具体属性
 # - "ecs:service" 表示这是ECS服务的属性
 # - "DesiredCount" 表示要调整的是服务的期望任务数量
 # 自动扩展系统将通过增加或减少运行的任务数量来实现扩展和收缩
 scalable_dimension = "ecs:service:DesiredCount"
 
 # 服务命名空间，指定资源所属的AWS服务类型
 # - "ecs" 表示这是Amazon Elastic Container Service服务
 # 这告诉AWS自动扩展系统我们要操作的是ECS服务，而不是其他类型的AWS服务
 service_namespace = "ecs"
 
 depends_on = [ aws_ecs_service.taskoverflow ]  # 依赖于ECS服务，确保先创建服务
}

# 定义基于CPU使用率的自动扩展策略
resource "aws_appautoscaling_policy" "taskoverflow-cpu" {
 name = "taskoverflow-cpu"                      # 策略名称
 policy_type = "TargetTrackingScaling"          # 策略类型：目标跟踪扩展，自动跟踪指定指标
 
 # 引用上面定义的资源ID，确保策略应用到正确的资源
 resource_id = aws_appautoscaling_target.taskoverflow.resource_id
 
 # 引用上面定义的扩展维度，确保策略调整正确的属性
 scalable_dimension = aws_appautoscaling_target.taskoverflow.scalable_dimension
 
 # 引用上面定义的服务命名空间，确保策略在正确的服务范围内操作
 service_namespace = aws_appautoscaling_target.taskoverflow.service_namespace
 
 # 目标跟踪配置 - 定义扩展的具体规则
 target_tracking_scaling_policy_configuration {
   # 使用预定义的指标规范 - ECS服务平均CPU使用率
   predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageCPUUtilization"
   }
   target_value = 20  # 目标值为20%，即当CPU使用率超过20%时扩展，低于20%时收缩
 }
}