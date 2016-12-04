function R=estimateR(w)
    R=zeros(3,3);
    R(1,1)=cos(w(1))*cos(w(3));
    R(1,2)=cos(w(1))*sin(w(3));
    R(1,3)=-sin(w(1));
    
    R(2,1)=sin(w(2))*sin(w(1))*cos(w(3))-cos(w(2))*sin(w(3));
    R(2,2)=sin(w(2))*sin(w(1))*sin(w(3))+cos(w(2))*cos(w(3));
    R(2,3)=sin(w(2))*cos(w(1));
    
    R(3,1)=cos(w(2))*sin(w(1))*cos(w(3))+sin(w(2))*sin(w(3));
    R(3,2)=cos(w(2))*sin(w(1))*sin(w(3))-sin(w(2))*cos(w(3));
    R(3,3)=cos(w(2))*cos(w(1));
end