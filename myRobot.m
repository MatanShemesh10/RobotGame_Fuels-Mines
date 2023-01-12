function [move,mem] = myRobot(env,mem)
%Environment Struct
% info,  STRUCT{team, fuel, myPos, oppPos}
% basic, STRUCT{walls, rRbt, rMF, lmax}
% mines, STRUCT{nMine, mPos, mineScr, mineExist} 
% fuels, STRUCT{nFuel, fPos, fuelScr, fExist}
%Memory Struct
% path, STRUCT{start, dest, pathpt, nPt, proc, lv}

%% Initial
oppPos=env.info.opPos;
oppFuel=env.info.fuel_op;
pos=env.info.myPos;
myFuel=env.info.fuel;

fExist=env.fuels.fExist;
nFuel=env.fuels.nFuel; 
fPos=env.fuels.fPos;

nMine=env.mines.nMine;
mPos=env.mines.mPos;
mExist=env.mines.mExist;

myDis = @(a,b) sqrt( (a(1)-b(1))^2 + (a(2)-b(2))^2); 
%anonymous function does calculate distance between 2 points

%% Fuel check

%finding the nearst fuel
for i=1:nFuel
    if fExist(i)~=false
        nearest_fuel=fPos(i,:);
        lowest_dis_value_fuel=myDis(pos,fPos(i,:));
        break;
    end
end

for j=i:nFuel
    if (fExist(j)==false)
        continue
    end
    if (myDis(pos,fPos(j,:)) > myDis(oppPos,fPos(j,:))) %if the opponent is closer to the fuel skip the fuel
        continue
    end    
    if myDis(pos,fPos(j,:))<lowest_dis_value_fuel
        lowest_dis_value_fuel=myDis(pos,fPos(j,:));
        nearest_fuel=fPos(j,:);
    end
end

d_y=nearest_fuel(2)-pos(2); %gradient calculation
d_x=nearest_fuel(1)-pos(1);
m_fule = abs(d_y/d_x);
ySign = sign(d_y);
xSign = sign(d_x);

if(abs(d_y) > abs(d_x))
    move(2) = 0.25 * ySign;
    move(1) = 0.25 * xSign / m_fule;
else
    move(2) = 0.25 * ySign * m_fule;
    move(1) = 0.25 * xSign; 
end

saving_move=move;



%% Attack and Defense

  %if the opponent is closer then the fuel then goes to the opponent
if(myDis(pos,oppPos) < myDis(pos,nearest_fuel) && myFuel > oppFuel) 
    d_y=oppPos(2)-pos(2);
    d_x=oppPos(1)-pos(1);
    m_attack = abs(d_y/d_x);
    ySign = sign(d_y);
    xSign = sign(d_x);
    
    if(abs(d_y) > abs(d_x))
        move(2) = 0.25 * ySign;
        move(1) = 0.25 * xSign / m_attack;
    else
        move(2) = 0.25 * ySign * m_attack;
        move(1) = 0.25 * xSign; 
    end
end

if(myDis(pos,oppPos) < 1.2 && myFuel < oppFuel) %defence, go opposite from the opponent
    d_y=oppPos(2)-pos(2);
    d_x=oppPos(1)-pos(1);
    m_defence = abs(d_y/d_x);
    ySign = sign(d_y)*(-1);
    xSign = sign(d_x)*(-1);
    
    if(abs(d_y) > abs(d_x))
        move(2) = 0.25 * ySign;
        move(1) = 0.25 * xSign / m_defence;
    else
        move(2) = 0.25 * ySign * m_defence;
        move(1) = 0.25 * xSign; 
    end
end


%% Mines

for i=1:nMine
    if mExist(i)~=false
        nearest_Mine=mPos(i,:);
        lowest_dis_value_Mine=myDis(pos,mPos(i,:));
        break;
    end
end

for j=i:nMine
    if (mExist(j)==false)
        continue
    end
    if myDis(pos,mPos(j,:))<lowest_dis_value_Mine
        nearest_Mine=mPos(j,:);
        lowest_dis_value_Mine=myDis(pos,mPos(j,:));
    end
end

function result = IsOnAMine(x1,y1,x2,y2)
    r1=0.3;
    r2=0.4;
    distSq = sqrt((x1 - x2)^2 + (y1 - y2)^2);
    radSumSq = (r1 + r2);
    if (distSq > radSumSq)
        result = false;
    else
        result = true;
    end
end

    newPos(1)=pos(1) + move(1);
    newPos(2)=pos(2) + move(2);
    current_mine=nearest_Mine;
    if (IsOnAMine(newPos(1),newPos(2),current_mine(1),current_mine(2)))       
        new_m = -1/m_fule;
        dest = 1;
        
        a = 1 + (new_m^2);
        b = -2*(new_m^2)*(current_mine(1)) - 2*current_mine(1);
        c = (new_m^2)*(current_mine(1)^2) + (current_mine(1)^2) - (dest^2);
        p=[a b c];

        x_array = roots(p);
        y1 = current_mine(2) - new_m*(current_mine(1) - x_array(1));
        y2 = current_mine(2) - new_m*(current_mine(1) - x_array(2));
        point1=[x_array(1) y1];
        point2=[x_array(2) y2];

        if(myDis(point1,nearest_fuel) > myDis(point2,nearest_fuel))
            new_x=x_array(2);
            new_y=y2;
        else
            new_x=x_array(1);
            new_y=y1;
        end

        d_y=new_y-pos(2);
        d_x=new_x-pos(1);
        m_around_mine = abs(d_y/d_x);
        ySign = sign(d_y);
        xSign = sign(d_x);
        
        if(abs(d_y) > abs(d_x))
            move(2) = 0.25 * ySign;
            move(1) = 0.25 * xSign / m_around_mine;
        else
            move(2) = 0.25 * ySign * m_around_mine;
            move(1) = 0.25 * xSign; 
        end
    end

     if(myDis(current_mine,pos)+1 > myDis(nearest_fuel,pos))
        move = saving_move;
     end

%% Fuel exist check
k=0;
for i=1:nFuel
    if (fExist(i)==true)
        k=k+1;
    end
end

 if (k<=0) %no fuel in the stage
    move=[0 0];
 end

 if(k<=1 && myDis(pos,nearest_fuel)>myDis(oppPos,nearest_fuel))
    move=[0 0];
 end

end