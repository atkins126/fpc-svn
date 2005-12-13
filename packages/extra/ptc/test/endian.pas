{$IFDEF VER1_0}
  {$IFDEF ENDIAN_LITTLE}
    {$DEFINE FPC_LITTLE_ENDIAN}
  {$ENDIF ENDIAN_LITTLE}
  {$IFDEF ENDIAN_BIG}
    {$DEFINE FPC_BIG_ENDIAN}
  {$ENDIF ENDIAN_BIG}
{$ENDIF VER1_0}

{$IFDEF FPC_LITTLE_ENDIAN}
  {$IFDEF FPC_BIG_ENDIAN}
    {$FATAL Both FPC_LITTLE_ENDIAN and FPC_BIG_ENDIAN defined?!}
  {$ENDIF FPC_BIG_ENDIAN}
{$ELSE FPC_LITTLE_ENDIAN}
  {$IFNDEF FPC_BIG_ENDIAN}
    {$FATAL Neither FPC_LITTLE_ENDIAN, nor FPC_BIG_ENDIAN defined?!}
  {$ENDIF FPC_BIG_ENDIAN}
{$ENDIF FPC_LITTLE_ENDIAN}

{$IFDEF FPC_LITTLE_ENDIAN}
  {$INFO FPC_LITTLE_ENDIAN}
{$ENDIF FPC_LITTLE_ENDIAN}
{$IFDEF FPC_BIG_ENDIAN}
  {$INFO FPC_BIG_ENDIAN}
{$ENDIF FPC_BIG_ENDIAN}
