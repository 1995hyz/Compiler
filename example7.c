struct s {
	int a;
	char b;
	int d;
};



int f() {
	struct s *s1;
	struct s s2;
	int e;
	char x;
	e = s1->d;
	x = s2.b;
}
