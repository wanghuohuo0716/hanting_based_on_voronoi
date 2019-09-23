# 本仓库是对论文《Intercepting Rogue Robots: An Algorithm for Capturing Multiple Evaders With Multiple Pursuers》的复现，基于voronoi图最小化围捕算法
![image](https://github.com/wanghuohuo0716/hanting_based_on_voronoi/blob/master/image/hanting.gif)
## 循环控制

### 1. 判断所有的evader是否被抓住

### 2. 获取各个agent的位置

### 3. 计算场上或者的agent维诺图

- 将active的agent的index选出来
- 把这些agent的pos放到一个数组中
- 计算voronoi图

	- 要计算维诺图的无穷远边与凸多边形的交点，因为有无穷大，无法计算pursuer的的速度
	- 所以必须设置边界，所有点在这个边界内运动，否则会出现计算nan，无法计算
	- 需要对每个元胞构成的voronoi图的顶点重新分配，把无穷远的点替换成直线的交点

		- 预处理：遍历所有的元胞，把元胞C在正方形外的顶点和无穷远的顶点ID都删除掉，只保留在正方形内的顶点

			- 如果顶点在正方形上怎么办，作为有界区域处理，不管他

		- 从vx，vy中倒序查找点，第二行最后一列是终点，第一行最后一列是起点，检测这样的线段是否与正方形的线段有交点

			- 函数中已经把重复的点去掉了

		- 有就把交点按顺序储存到V中（避免与之前的交点的ID产生冲突），接着把正方形的顶点也储存进去，打上ID，没有就过

			- 需要检测是否有重复的点！

		- 所有的边都检查完，为V中新添加的点找最近的两个元胞（用小于等于），并且为元胞打上ID

			- 有点到三个元胞的距离相同，但是计算法先，这个点是元胞内部的点，记得在i上+1即可
			- 正方形角点计算选择最近的距离
			- 其他距离选择两个元胞

### 4. 计算pursuer和evader速度方向

- 寻找pursuer元胞周围的neightbor是否有evader的元胞，如果有，找到最近的evader元胞，计算边界的型心；如果没有则计算最近的evader，速度方向朝向evader。

	- 找到两个元胞公共的顶点，且公共顶点数为2，则这两个元胞相邻
	- 先找元胞的neightbor，然后在neightbor中找evader，在evader中找最近的evader

- 寻找evader 元胞周围的neightbor是否有pursuer的元胞，如果有，计算evader的多边形的型心，朝着型心运动；如果没有则计算最近的pursuer，速度方向朝向pursuer的反方向。
- 根据论文公式计算输入u

### 5. 运动到指定点的位置

### 6. 计算是否触发捕获

- 计算每个evader最近的pursuer距离，如果小于rc就设置被捕获状态，停止运动，pursuer更新target
- 全部evader都被捕获，停止运动

## MATLAB图像处理

### 1. 如何给图填充颜色

- 不处理

### 2. 如何取消voronoi图的蓝点

- hold off

### 3. 如何更新各个点的位置，同时上一时刻的位置消失

- hold off


### 4. 没必要在画图上费工夫，理解即可，只区分evader和pursuer，plot三角形和圆圈即可。

## bug记录

### 1. 无法运动，卡死在这里了，对称陷阱

- 捕获距离小于计算的步长就会出现对称陷阱

### 2. 会出现最后时刻，点聚集到一起，与正方形无交点的情况

### 3. X4也出现了朝着死去evader跑去，似乎不是dis的问题，但也可能是最后时刻没有更新的原因

### 4. 有X3会朝死去的evader跑去，因为设置的min_dis太小了，设置大一点即可

### 5. X2也出现了朝着死去evader跑去，似乎不是dis的问题，都是在最后一个点的时候出现的情况
