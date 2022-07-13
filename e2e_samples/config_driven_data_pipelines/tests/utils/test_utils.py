import numbers


def assert_rows(df, columns, rows):
    for row in rows:
        row_list = []
        assert len(columns) == len(row)
        for i in range(0, len(columns)):
            if isinstance(row[i], numbers.Number):
                row_list.append(f"({columns[i]} = {row[i]})")
            else:
                row_list.append(f"({columns[i]} = '{row[i]}')")
        expr = f"ANY({' AND '.join(row_list)})"
        print(f"assert df.selectExpr({expr}).collect()[0][0]")
        assert df.selectExpr(expr).collect()[0][0]
