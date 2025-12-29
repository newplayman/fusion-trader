# Phase3–4 Lab: CEX → DEX LP Guard

本实验室用于：
- 离线 replay CEX 行情 / 风控 / 决策日志
- 评估“是否应撤出 / 调整 DEX LP”的风控触发器
- 不影响任何实盘执行逻辑（shadow only）

原则：
- VPS 只跑实盘 + 打日志
- Mac 做 replay / 统计 / 研发
