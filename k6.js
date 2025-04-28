// 导入 k6 的 HTTP 模块，用于发送 HTTP 请求
import http from 'k6/http';

// 导入 sleep 和 check 函数
// sleep: 控制虚拟用户之间的等待时间
// check: 用于验证响应是否符合预期
import { sleep, check } from 'k6';

// 定义负载测试的配置选项
export const options = {
  // 定义测试的不同阶段
  stages: [
    // 第一阶段：1分钟内逐渐增加到1000个并发用户
    // target: 目标并发用户数
    // duration: 这个阶段持续的时间
    { target: 1000, duration: '1m' }, 
    
    // 第二阶段：保持5000个并发用户持续10分钟
    { target: 5000, duration: '10m' },
  ],
};

// 定义每个虚拟用户要执行的测试脚本
export default function () {
  // 向指定的 API 端点发送 GET 请求
  // 使用实际的负载均衡器 DNS 名称
  const res = http.get('http://taskoverflow-1479732834.us-east-1.elb.amazonaws.com/api/v1/todos');
  
  // 检查响应状态码是否为 200（成功）
  // 这是一个验证响应是否正常的断言
  check(res, { 
    'status was 200': (r) => r.status == 200 
  });
  
  // 在每个虚拟用户的请求之间暂停1秒
  // 模拟真实用户访问的间隔
  sleep(1);
}