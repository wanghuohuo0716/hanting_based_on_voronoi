
clear all
close all
pursuers_num=4;
evaders_num=8;
agents_sum=pursuers_num+evaders_num;
t_step=0.01;
capture_dis=0.03;
counter=0;
L=1; %边长为1的正方形
square_x=[0 0 L L 0]; % 5个顶点的坐标,第一个和最后一个重合才能形成封闭图形
square_y=[0 L L 0 0];
for i=1:agents_sum
    agents(i).pos=rand(1,2);
    agents(i).active=1; % evader 存活flag
    agents(i).min_dis=100;
end
figure()
while 1
    if sum([agents(pursuers_num+1:agents_sum).active])==0 % 所有的evader都被抓到了
        % 输出视频
        v = VideoWriter('wanghuohuo2.avi');
        v.FrameRate=4;
        open(v);
        writeVideo(v, F);
        close(v);
        return;     %当所有的evader被抓到就退出循环，结束程序，否则继续执行else
    else
        temp_pos=[];
        % 计算active的agents的voronoi图
        index_active=[agents(:).active];
        index_active = find(index_active);
        temp_pos=[agents(index_active).pos];
        temp_pos=reshape(temp_pos,2,length(index_active))'; %需要转置下
        [vx,vy] = voronoi(temp_pos(:,1),temp_pos(:,2));%为什么vxvy有两行？？
        [V,C] = voronoin(temp_pos);%V,C分别代表什么？
        
        % 画pursuer和evader的位置
        plot(temp_pos(1:pursuers_num,1),temp_pos(1:pursuers_num,2),'go',...
             temp_pos(pursuers_num+1:length(index_active),1),temp_pos(pursuers_num+1:length(index_active),2),'r*',...
            vx,vy,'k-')
        
        % 打lable
        plabels = arrayfun(@(n) {sprintf('X%d', n)}, (index_active(:))');
        hold on
        Hpl = text(temp_pos(:,1), temp_pos(:,2), plabels, ...
              'HorizontalAlignment','left', ...
              'BackgroundColor', 'none');
        xlim([0 1]);
        ylim([0 1]);
        
        % 更新有限区域内的元胞顶点，计算up的关键！预处理：遍历所有的元胞，把元胞C在正方形外的顶点和无穷远的顶点ID都删除掉，只保留在正方形内的顶点
        for i=1:length(C)
            out_index=[];
            inf_index=[];
            if sum(C{i}==1) % 找到元胞中无穷远的点的索引
                inf_index=find(C{i}==1);
            end
            for j=1:length(C{i}) % 找到元胞中正方形外的点的索引
                [in on]= inpolygon(V(C{i}(j),1),V(C{i}(j),2),square_x,square_y);
                if in==0 && on==0 % 在外部
                    out_index=[out_index j];
                end
            end
            out_index=[inf_index out_index]; % 清除无穷远点和外部点的索引，必须一起清除，否则先后顺序会导致删除后元胞顶点数目发生变化
            C{i}(out_index)=[]; % 不能清除V的顶点，否则C{i}中顶点的无法索引
        end
        
        %从vx，vy中倒序查找点，第二行最后一列是终点，第一行最后一列是起点，检测这样的线段是否与正方形的线段有交点
        cross_point=[];
        for i=1:length(vx)
            [xi,yi] = polyxpoly(vx(:,i),vy(:,i),square_x,square_y,'unique');
            cross_point=[cross_point;[xi yi]];
        end
        
        % 把交点和正方形的顶点按顺序储存到V中（不能清除V的顶点，否则C{i}中顶点的无法索引），打上ID
        old_V=V;
        V=[V;cross_point];
        
        % V中新添加的点找最近的两个元胞（用小于等于），并且为元胞打上ID
        C_pos=temp_pos; % 保存元胞的位置
        for i=length(old_V)+1:length(V)
            V_dist=sum(abs(V(i,:)-C_pos).^2,2).^(1/2);
            V_index=find(V_dist==min(V_dist)); % 距离最近的元胞
            if length(V_index)==2
                C{V_index(1)}=[C{V_index(1)} i];
                C{V_index(2)}=[C{V_index(2)} i];
            else
                C{V_index}=[C{V_index} i]; % 把这个点加入到元胞的顶点列表中
                V_dist(V_index)=max(V_dist); 
                V_index=find(V_dist==min(V_dist)); % 倒数第二小的index，实际两者是相同的
                C{V_index}=[C{V_index} i];
            end
        end
        
        % 把正方形的角点加入到V中，添加到最近的元胞，一般顶点只被一个占有，特殊情况也可能两个都占有
        square=[square_x;square_y]';
        square(end,:)=[]; % 去掉正方形重复的角点
        old_V=V;
        V=[V; square];
        for i=length(old_V)+1:length(V)
            V_dist=sum(abs(V(i,:)-C_pos).^2,2).^(1/2);
            V_index=find(V_dist==min(V_dist)); % 距离最近的元胞
            if length(V_index)==2
                C{V_index(1)}=[C{V_index(1)} i];
                C{V_index(2)}=[C{V_index(2)} i];
            else
                C{V_index}=[C{V_index} i]; % 把这个点加入到元胞的顶点列表中
            end
        end
        
        % 计算元胞的neighbor，核心！
        common_index=[];
        common_id=[];
        for i=1:length(C) % 不能用agents_sum，否则会把死掉的evader也计算进去
            for j=1:length(C)
                if i~=j
                    temp_common=intersect(C{i},C{j});
                    if length(temp_common)==2
                        common_index=[common_index;temp_common];
                        common_id=[common_id;j];
                    end
                end
            end
            if length(common_id)~=0 % 避免出现某两个common_id为空导致程序不能运行
                agents(i).neightbor.id=common_id;
                agents(i).neightbor.shared_boundary=common_index;
                agents(i).neightbor.mid_point= (V(common_index(:,1),:) + V(common_index(:,2),:))/2;  
                common_index=[]; %清空
                common_id=[];
            end
        end
        for i=1:agents_sum
            agents(i).target=[];
        end
        
        % 根据公式计算up
        for i=1:pursuers_num
            if sum(agents(i).neightbor.id>pursuers_num) % 如果pursuer周围有evader则走中点
                near_id=find(agents(i).neightbor.id>pursuers_num); % 找neighbor是evader的id
                temp_err=agents(i).pos-agents(i).neightbor.mid_point(near_id,:);
                temp_dis=sum(abs(temp_err).^2,2).^(1/2);
                min_index = find(temp_dis==min(min(temp_dis))) + sum(agents(i).neightbor.id<=pursuers_num); % 加上pursuer的ID,很重要，因为temp_dis舍去了前面id
                agents(i).target=agents(i).neightbor.mid_point(min_index,:); % 找到最近的evader
                agents(i).up=(agents(i).target-agents(i).pos)/norm((agents(i).target-agents(i).pos));
            else % 如果pursuer周围没有evader则朝最近的evader走过去
                for j=(pursuers_num+1):agents_sum
                    if agents(j).active
                        dis=norm(agents(i).pos - agents(j).pos);
                        if dis < agents(i).min_dis
                            agents(i).min_dis=dis; %计算每个evader到所有的pursuer的最小距离
                            agents(i).target=agents(j).pos;
                            agents(i).up=(agents(i).target-agents(i).pos)/norm((agents(i).target-agents(i).pos));
                        end
                    end
                end
            end
        end
        
        % 计算Ue，控制策略是往每个evader所在元胞的形心移动
        % 先遍历evader的元胞，计算出元胞的形心位置
%         cal=0;
%         for i=1:agents_sum
%             if agents(i).active
%                 cal=cal+1;
%             end
%         end
%         k1=5;
%         for i=pursuers_num+1:agents_sum
%             if agents(i).active
%                 xe=[];
%                 ye=[]; 
%                 for j=1:length(C{k1})
%                     xe=[xe V(C{k1}(j),1)];
%                     ye=[ye V(C{k1}(j),2)];
%                 end
%                 polyin = polyshape(xe,ye);
%                 [xc,yc]=centroid(polyin);
%                 agents(i).target=[xc,yc];
%                 agents(i).ue=(agents(i).target-agents(i).pos)/norm((agents(i).target-agents(i).pos));
%             end
%             k1=k1+1;
%             if k1>cal
%                 break;
%             end
%         end


        %计算Ue，控制策略是往每个evader所在元胞的形心移动
        %思路是，需要通过C，构造一个储存evader所在元胞的形心的矩阵（虽然C在每次有evader死掉后都会更新，
        %                      其长度会变短，但是总是从C{5}开始到末尾都是储存的evader的索引，所以通过C
        %                      能够很好的遍历完所有存活的evader的索引）
        %然后再遍历所有evader，找到其中存活的，按顺序从上到下从上述矩阵里取形心坐标当目标
        cen=[];%用来储存质心的矩阵
        for i=pursuers_num+1:length(C)
            xe=[];
            ye=[];
            for j=1:length(C{i})
                xe=[xe V(C{i}(j),1)];
                ye=[ye V(C{i}(j),2)];
            end
            polyin = polyshape(xe,ye);
            [xc,yc]=centroid(polyin);
            cen=[cen;[xc yc]];
        end
        k=1;
        for i=pursuers_num+1:agents_sum
            if agents(i).active 
                agents(i).target=cen(k,:);
                agents(i).ue=(agents(i).target-agents(i).pos)/norm((agents(i).target-agents(i).pos));
                k=k+1;
            end
        end
        
        %画出移动路径
        for i=1:pursuers_num
            hold on
            plot([agents(i).pos(1,1);agents(i).target(1,1)], [agents(i).pos(1,2);agents(i).target(1,2)],'g-')
        end
        %只更新active的pursuers位置
        for i=1:pursuers_num
            if agents(i).active
                agents(i).pos =agents(i).pos + t_step * agents(i).up;
            end
        end
        
        %只更新active的evader的位置
        for i=pursuers_num+1:agents_sum
            if agents(i).active
                agents(i).pos = agents(i).pos + t_step * agents(i).ue;
            end
        end
        
        % 判断是否触发被捕获
        for i=(pursuers_num+1):agents_sum
            if agents(i).active
                for j=1:pursuers_num
                    dis=norm(agents(i).pos - agents(j).pos); 
                    if dis < agents(i).min_dis
                        agents(i).min_dis=dis; %计算每个evader到所有的pursuer的最小距离
                    end
                end
                % 判断evader被成功捕获的触发条件
                if agents(i).min_dis < capture_dis
                    agents(i).active=0;
                    for j=1:pursuers_num
                        agents(j).min_dis=100;% evader死掉后，需要更新下pursuer的min_dis距离，否则会朝着死掉的evader继续前进
                    end
                    hold on
                    plot(agents(i).pos(1,1),agents(i).pos(1,2),'g*')
                end
            end
        end
    end
    hold off
    counter=counter+1;
    F(counter) = getframe(gcf); %gcf并不是提前定义的变量，直接用就行！
    pause(0.01)
end
